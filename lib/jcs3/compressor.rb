module Jcs3

  class Compressor
    attr_reader :root_dir

    def initialize(directory)
      @root_dir = directory
    end

    def zippable_files
      Dir.glob("#{@root_dir}/**/*.{html,css,js}")
    end

    def zip(file)
      system("gzip -cn9 #{file} > #{file}.gz")
    end

    def zip_files
      zippable_files.each { |f| zip(f) }
    end

  end

end