module Clients
  class RegistrationsController < ApplicationController
    before_action :require_authentication!

    layout "client"

    def new
      @client = ::Client.new
    end

    def create
      @client = ::Client.new(client_params.merge(user: current_user))

      brreg = BrregService.lookup(@client.org_number.to_s)
      unless brreg.success?
        @client.errors.add(:org_number, brreg.error)
        render :new, status: :unprocessable_entity
        return
      end

      @client.org_name    = brreg.name
      @client.org_address = brreg.address.presence || @client.org_address
      @client.verified_at = Time.current

      if @client.save
        current_user.update!(role: :client)
        redirect_to clients_dashboard_path, notice: "Welcome to Bookify! Your organisation has been verified."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def client_params
      params.require(:client).permit(:org_number, :org_name, :org_address)
    end
  end
end
