class CreateDeployments < ActiveRecord::Migration[7.0]
  def change
    create_table :deployments, id: :uuid do |t|
      t.references :app, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
