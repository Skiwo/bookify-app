class SkillPagesController < ApplicationController
  SUPPORTED_SKILLS = %w[
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

  def show
    @skill = params[:skill]
    raise ActionController::RoutingError, "Unknown skill" unless SUPPORTED_SKILLS.include?(@skill)

    @shops = Shop.active.public_shop
                 .where("EXISTS (SELECT 1 FROM unnest(skill_tags) AS tag WHERE tag ILIKE ?)", @skill)
                 .order(:name)
  end
end
