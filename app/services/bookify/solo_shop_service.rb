module Bookify
  # Creates (or finds) a solo shop for a freelancer who enables direct booking.
  #
  # A solo shop is a regular Shop where:
  #   - owner = the freelancer user
  #   - sole roster member = the freelancer themselves
  #   - commission_percent = 0 (no middleman cut)
  #   - solo = true (flag to distinguish from regular shops)
  #   - visibility = public_shop
  #
  # The freelancer's bookify_pop_worker_id is reused for both the shop's
  # pop_worker_id (commission line payee, though 0%) and the ShopMember's
  # bookify_pop_worker_id (work payout recipient). One POP enrollment — many uses.
  class SoloShopService
    def self.find_or_create!(user)
      existing = Shop.find_by(owner: user, solo: true)
      return existing if existing

      ActiveRecord::Base.transaction do
        slug = generate_slug(user)

        shop = Shop.create!(
          owner:              user,
          name:               user.name,
          slug:               slug,
          description:        user.bio.presence || user.headline.presence,
          visibility:         :public_shop,
          status:             :active,
          commission_percent: 0,
          solo:               true,
          pop_worker_id:      user.bookify_pop_worker_id
        )

        # Enrollment record — owner acts as booker for themselves
        enrollment = Enrollment.find_or_initialize_by(booker: user, email: user.email)
        unless enrollment.persisted?
          enrollment.assign_attributes(
            name:          user.name,
            freelancer:    user,
            pop_worker_id: user.bookify_pop_worker_id,
            invited_at:    Time.current,
            onboarded_at:  Time.current
          )
          enrollment.status = :invited
          enrollment.save!
        end
        enrollment.update_columns(
          status:           Enrollment.statuses[:active],
          pop_worker_id:    user.bookify_pop_worker_id,
          freelancer_id:    user.id
        )

        # The freelancer is their own roster member
        ShopMember.find_or_create_by!(shop: shop, enrollment: enrollment) do |m|
          m.status                = :active
          m.bookify_pop_worker_id = user.bookify_pop_worker_id
          m.invited_at            = Time.current
          m.accepted_at           = Time.current
        end

        shop
      end
    end

    # Sync solo shop attributes when freelancer updates their profile
    def self.sync!(user)
      shop = Shop.find_by(owner: user, solo: true)
      return unless shop

      shop.update!(
        name:          user.name,
        description:   user.bio.presence || user.headline.presence || shop.description,
        pop_worker_id: user.bookify_pop_worker_id || shop.pop_worker_id
      )

      member = shop.shop_members.find_by(enrollment: { freelancer_id: user.id })
      member&.update_columns(bookify_pop_worker_id: user.bookify_pop_worker_id) if user.bookify_pop_worker_id.present?
    end

    private

    def self.generate_slug(user)
      base = user.name.to_s.downcase
                  .unicode_normalize(:nfkd)
                  .gsub(/[^\x00-\x7f]/, "")
                  .gsub(/[^a-z0-9]+/, "-")
                  .gsub(/^-|-$/, "")
                  .presence || "freelancer"

      slug = base
      n    = 2
      while Shop.exists?(slug: slug)
        slug = "#{base}-#{n}"
        n += 1
      end
      slug
    end
  end
end
