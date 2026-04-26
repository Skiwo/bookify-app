module RoleLayout
  extend ActiveSupport::Concern

  included do
    layout :resolve_layout
  end

  private

  def resolve_layout
    case current_user&.role
    when "shop_owner"  then "shop"
    when "client"      then "client"
    when "freelancer"  then "freelancer"
    when "booker"      then "booker"
    else "application"
    end
  end
end
