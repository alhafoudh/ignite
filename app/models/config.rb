class Config < ApplicationRecord
  after_save_commit :reconfigure_reverse_proxy

  def self.instance
    first!
  rescue ActiveRecord::RecordNotFound
    Config.create!(
      singleton_guard: 0,
    )
  end

  def self.current
    Current.config || instance
  end

  def reconfigure_reverse_proxy
    return unless saved_change_to_base_host?

    ReverseProxyDeployer.new.configure
  end
end
