class AddInvitationTokenToShopMembers < ActiveRecord::Migration[8.0]
  def change
    add_column :shop_members, :invitation_token, :string
    add_index :shop_members, :invitation_token, unique: true
  end
end
