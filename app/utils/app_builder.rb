class AppBuilder
  include Tar

  attr_reader :file

  def initialize(file)
    @file = file
  end

  def run(&block)
    Dir.mktmpdir do |tmpdir|
      untar(file, tmpdir)

      builder_image = Docker::Image.create(fromImage: 'gliderlabs/herokuish:latest-22')
      container = Docker::Container.create(
        name: "builder-#{SecureRandom.hex}",
        Image: builder_image.id,
        Cmd: %w[/build],
        Env: [
          "CACHE_PATH=/cache"
        ],
        HostConfig: {
          Binds: [
            "#{Rails.root.join('tmp', 'builder-cache')}:/cache",
            "#{tmpdir}:/tmp/app",
          ]
        },
      )
      container.start
      container.attach(stdout: true, stderr: true, tty: true, logs: true, stream: true) do |chunk|
        block.call(chunk)
      end
      container.wait
      image = container.commit
      container.delete(force: true)
      image
    end
  end
end