class AddLastDeployedAtToApps < ActiveRecord::Migration[7.0]
  def change
    add_column :apps, :last_deployed_at, :datetime, null: true
    add_index :apps, :last_deployed_at
  end
end
