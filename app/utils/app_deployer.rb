class AppDeployer < Deployer
  attr_reader :app

  def initialize(app)
    @app = app
  end

  def resource
    Docker::Container.all(all: true).find do |container|
      names = container.info["Names"]
      names.include?("/#{app.container_name}")
    end
  end

  def deploy(image)
    Docker::Container.create(
      name: app.container_name,
      Image: image,
      Cmd: %w[/start web],
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