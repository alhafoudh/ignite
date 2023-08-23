class NetworkDeployer < Deployer
  NETWORK_NAME = "ignite"

  def resource
    Docker::Network.all(all: true).find do |network|
      name = network.info["Name"]
      name == NETWORK_NAME
    end
  end

  def deploy(*)
    Docker::Network.create(
      NETWORK_NAME,
      Driver: "bridge",
    )
  end

  def deployed?
    resource_deployed?
  end
end