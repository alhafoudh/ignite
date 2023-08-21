class App < ApplicationRecord
  after_destroy_commit :destroy_container

  def container_name
    "app-#{id}"
  end

  def hostname
    "#{name}.ignite.127.0.0.1.nip.io"
  end

  def url
    URI::HTTP.build(host: hostname).to_s
  end

  def build_deployer
    AppDeployer.new(self)
  end

  def build_reverse_proxy_deployer
    ReverseProxyDeployer.new
  end

  def destroy_container
    build_deployer.undeploy
    build_reverse_proxy_deployer.configure
  end
end
