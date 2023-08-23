class CreateConfigs < ActiveRecord::Migration[7.0]
  def change
    create_table :configs, id: :uuid do |t|
      t.integer :singleton_guard, null: false, default: 0
      t.string :base_host, null: false, default: 'ignite.127.0.0.1.nip.io'

      t.timestamps
    end

    add_index :configs, :singleton_guard, unique: true
  end
end
