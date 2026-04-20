class SkillPagesController < ApplicationController
  SUPPORTED_SKILLS = %w[
    kokker bartendere servitorer cateringassistenter renholdere
    vektere resepsjonister konferanseverter fotografer
    musikere dj-er lydteknikere lysteknikere rigger
    snekkere malere elektrikere rorleggere
    it-konsulenter grafikere tekstforfattere oversettere
    regnskapsforere administratorer prosjektledere
    sykepleiere helsefagarbeidere barnehageassistenter laerere
    personlige-trenere massorer yogainstruktorer
    sjaforer budbringer lagerarbeidere
  ].freeze

  def show
    @skill = params[:skill]
    raise ActionController::RoutingError, "Unknown skill" unless SUPPORTED_SKILLS.include?(@skill)

    @shops = Shop.active.public_shop
                 .where("? = ANY(skill_tags)", @skill)
                 .order(:name)
  end
end
