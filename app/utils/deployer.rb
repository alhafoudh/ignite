class Deployer
  def resource
    raise NotImplementedError
  end

  def deploy(image)
    raise NotImplementedError
  end

  def undeploy
    resource.tap do |container|
      container&.remove(force: true)
    end
  end

  def deployed?
    container_deployed?
  end

  def resource_deployed?
    resource.present?
  end

  def container_deployed?
    resource_deployed? && resource.info["State"] == "running"
  end

  def ensure(image = nil)
    if deployed?
      resource
    else
      deploy(image)
    end
  end

  def redeploy(image = nil)
    undeploy
    image = image || current_image
    deploy(image)
  end

  def current_image
    (resource&.info || {})["Image"]
  end

  def wait_for_http(url, timeout: 5)
    Timeout.timeout(timeout) do
      loop do
        begin
          HTTP.get(url)
          break
        rescue
          sleep 1
        end
      end
    end
  end
end