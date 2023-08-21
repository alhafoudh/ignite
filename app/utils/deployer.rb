class Deployer
  def container
    raise NotImplementedError
  end

  def deploy(image)
    raise NotImplementedError
  end

  def undeploy
    container.tap do |container|
      container&.remove(force: true)
    end
  end

  def deployed?
    container.present? && container.info["State"] == "running"
  end

  def ensure(image = nil)
    if deployed?
      container
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
    (container&.info || {})["Image"]
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