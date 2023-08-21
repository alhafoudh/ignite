class ReverseProxyDeployer < Deployer
  CONTAINER_NAME = "reverse_proxy"
  IMAGE_NAME = "caddy:2.7.4-alpine"

  def container
    Docker::Container.all(all: true).find do |container|
      names = container.info["Names"]
      names.include?("/#{CONTAINER_NAME}")
    end
  end

  def deploy(*)
    Docker::Container.create(
      name: CONTAINER_NAME,
      Image: IMAGE_NAME,
      ExposedPorts: {
        "2019/tcp" => {},
        "80/tcp" => {},
        "443/tcp" => {},
      },
      HostConfig: {
        PortBindings: {
          "2019/tcp" => [{
            HostIp: "0.0.0.0",
            HostPort: "2019"
          }],
          "80/tcp" => [{
            HostIp: "0.0.0.0",
            HostPort: "80"
          }],
          "443/tcp" => [{
            HostIp: "0.0.0.0",
            HostPort: "443"
          }],
        },
        NetworkMode: "ignite"
      },
    ).tap do |container|
      container.store_file("/etc/caddy/Caddyfile", "{\n  admin :2019\n}\n")
      container.start
    end
  end

  def configure
    HTTP.post(
      "http://localhost:2019/load",
      json: {
        admin: {
          listen: "0.0.0.0:2019"
        },
        apps: {
          http: {
            servers: {
              reverse_proxy: {
                listen: [
                  ":80"
                ],
                routes: App.all.reduce([]) do |acc, app|
                  acc << {
                    match: [
                      host: [app.hostname],
                    ],
                    handle: [
                      {
                        handler: "reverse_proxy",
                        upstreams: [
                          {
                            dial: "#{app.container_name}:80"
                          }
                        ]
                      }
                    ]
                  }
                  acc
                end.flatten
              }
            }
          }
        }
      }
    ).tap do |response|
      unless response.status == 200
        binding.pry
      end
    end
  end

  def wait_ready
    wait_for_http("http://localhost:2019/config/")
  end
end