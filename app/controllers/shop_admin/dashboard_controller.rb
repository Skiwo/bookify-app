module ShopAdmin
  class DashboardController < BaseController
    def show
      @shop = current_shop
      @pending_jobs = @shop.jobs.includes(:client).draft.order(created_at: :desc).limit(5)
      @active_jobs = @shop.jobs.includes(:client, :assigned_member).in_progress.order(created_at: :desc).limit(5)
      @members_count = @shop.shop_members.active.count
    end
  end
end
