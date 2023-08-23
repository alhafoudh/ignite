class AppBuilder
  attr_reader :file

  def initialize(file)
    @file = file
  end

  def run(&block)
    builder_image = Docker::Image.create(fromImage: 'gliderlabs/herokuish:latest-22')
    container = Docker::Container.create(
      name: "builder-#{SecureRandom.hex}",
      Image: builder_image.id,
      Cmd: Shellwords.shellsplit("/bin/sh -c '/build && rm -rf /tmp/app'"),
      Env: [
        "CACHE_PATH=/cache"
      ],
      HostConfig: {
        Binds: [
          "/tmp/builer-cache:/cache",
        ]
      },
    )
    container.store_file("/tmp/app/.ignite_app", '')
    container.archive_in_stream("/tmp/app", overwrite: true) do
      file.read
    end
    container.start
    container.attach(stdout: true, stderr: true, tty: true, logs: true, stream: true) do |chunk|
      block.call(chunk)
    end
    container.wait
    container.exec(%w[rm -rf /tmp/app]) do |stream, chunk|
      block.call(chunk)
    end
    image = container.commit
    container.delete(force: true)
    image
  end
end