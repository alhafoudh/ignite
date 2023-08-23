class AddReverseProxyControlUrlToConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :configs, :reverse_proxy_control_url, :string, null: false, default: 'http://localhost:2019'
  end
end
