class AppDeployer < Deployer
  attr_reader :app
  attr_reader :image

  def initialize(app, image)
    @app = app
    @image = image
  end

  def container
    Docker::Container.all(all: true).find do |container|
      names = container.info["Names"]
      names.include?("/#{app.container_name}")
    end
  end

  def deploy
    Docker::Container.create(
      name: app.container_name,
      Image: image.id,
      Env: [
        "PORT=80",
      ],
      ExposedPorts: {
        "80/tcp" => {},
      },
      HostConfig: {
        PortBindings: {
          "80/tcp" => [{}],
        },
        NetworkMode: "ignite"
      },
    ).tap do |container|
      container.start
    end
  end
end