class SeedSkillsAndMigrateShopTags < ActiveRecord::Migration[8.0]
  SKILLS = %w[
    kokker bartendere servitorer cateringassistenter renholdere
    vektere resepsjonister konferanseverter fotografer videografer
    musikere dj-er lydteknikere lysteknikere rigger scenearbeidere
    snekkere malere elektrikere rorleggere murere flisleggere taktekkere
    gartnere landskapsarkitekter
    it-konsulenter grafikere tekstforfattere oversettere webdesignere utviklere
    regnskapsforere administratorer prosjektledere konsulenter forretningsanalytikere
    sykepleiere helsefagarbeidere barnehageassistenter laerere
    personlige-trenere massorer yogainstruktorer ernaerings-veiledere
    sjaforer budbringer lagerarbeidere flyttehjelpere transportarbeidere
    frisorer sminkorer neglteknikere
    eventplanleggere foredragsholdere
    mekanikere bilpleiere
    tannlegeassistenter veterinaerassistenter
  ].freeze

  def up
    skill_class = Class.new(ActiveRecord::Base) { self.table_name = "skills" }
    shop_skill_class = Class.new(ActiveRecord::Base) { self.table_name = "shop_skills" }
    shop_class = Class.new(ActiveRecord::Base) { self.table_name = "shops" }

    # 1. Seed skills (idempotent)
    SKILLS.each_with_index do |slug, idx|
      skill_class.find_or_create_by!(slug: slug) { |s| s.position = idx }
    end

    slug_to_id = skill_class.pluck(:slug, :id).to_h

    # 2. Migrate existing shop.skill_tags into shop_skills
    shop_class.where.not(skill_tags: []).find_each do |shop|
      Array(shop.skill_tags).each do |tag|
        normalized = tag.to_s.strip.downcase
        skill_id = slug_to_id[normalized]
        next unless skill_id
        shop_skill_class.find_or_create_by!(shop_id: shop.id, skill_id: skill_id)
      end
    end
  end

  def down
    execute "DELETE FROM shop_skills"
    execute "DELETE FROM skills"
  end
end
