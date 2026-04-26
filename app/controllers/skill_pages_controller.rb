class SkillPagesController < ApplicationController
  include RoleLayout

  def show
    @skill = Skill.find_by(slug: params[:skill])
    raise ActionController::RoutingError, "Unknown skill" unless @skill

    @shops = Shop.active.public_shop
                 .joins(:skills).where(skills: { id: @skill.id })
                 .distinct.order(:name)
  end
end
