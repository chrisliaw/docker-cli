
require 'openssl'

module Docker
  module Cli
    class Dockerfile

      class NoDockerfileFound < StandardError; end
      
      def self.find_available(root = Dir.getwd)
        Dir.glob("**/Dockerfile*")
      end

      def self.run_before?(dockerfile_path)
        DockerRunLog.instance.has_dockerfile_seen_before?(dockerfile_path)
      end

      # expect dockerfile is CONTENT, not file path
      def self.images(dockerfile)
        DockerRunLog.instance.dockerfile_images(dockerfile)
      end

      def initialize(file)
        @dfile = file
      end

      def render_dockerfile(vals = {}, &block)
        if @_df.nil?
          if @dfile.nil?
            @_df = nil
          else
            if File.exist?(@dfile)
              if is_erb_template?
                @_df = process_dockerfile_template(@dfile, vals)
              else
                @_df = File.read(@dfile)
              end
            else
              @_df = nil
            end
          end
        end
        @_df
      end

      def is_erb_template?
        if File.exist?(@dfile)
          cont = File.read(@dfile)
          (cont =~ /<%=/ and cont =~ /%>/) != nil
        else
          false
        end
      end

      def process_dockerfile_template(file, values = {})
        raise Error, "Given dockerfile to process as template not found" if not File.exist?(file)
        DockerfileTemplate::TemplateEngine.new.process(File.read(file), values) 
      end

    end
  end
end
