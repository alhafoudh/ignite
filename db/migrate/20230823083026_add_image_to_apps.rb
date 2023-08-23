class AddImageToApps < ActiveRecord::Migration[7.0]
  def change
    add_column :apps, :image, :string, null: true
  end
end
