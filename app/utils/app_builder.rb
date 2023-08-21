class AppBuilder
  include Tar

  attr_reader :file

  def initialize(file)
    @file = file
  end

  def run(&block)
    Dir.mktmpdir do |tmpdir|
      untar(file.tempfile, tmpdir)
      dockerfile = File.read(Rails.root.join('samples', 'Dockerfile'))
      File.write(File.join(tmpdir, 'Dockerfile'), dockerfile)

      Docker::Image.build_from_dir(tmpdir) do |v|
        lines = v.split("\r\n")
        lines.map do |line|
          if (log = JSON.parse(line)) && log.has_key?("stream")
            block.call(log["stream"])
          end
        end
      end
    end
  end
end