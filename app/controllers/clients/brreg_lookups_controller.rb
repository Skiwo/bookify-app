module Clients
  class BrregLookupsController < ApplicationController
    before_action :require_authentication!

    def show
      result = BrregService.lookup(params[:org_number].to_s.gsub(/\D/, ""))
      if result.success?
        render json: { name: result.name, address: result.address }
      else
        render json: { error: result.error }, status: :unprocessable_entity
      end
    end
  end
end
