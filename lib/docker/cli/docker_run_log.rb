
require 'singleton'
require 'yaml'

module Docker
  module Cli

    class NonEmptyRecord < StandardError; end

    class DockerRunLog
      include TR::CondUtils
      include Singleton

      def log(image, container, opts = {})
        if not_empty?(image) and not_empty?(container)
          logfile[image] = [] if logfile[image].nil?
          cont = { container: container, created_at: Time.now.to_i, last_run: Time.now.to_i } 
          cont = cont.merge(opts) if not_empty?(opts)
          logfile[image] << cont
          write
        end
      end

      #def log_dockerfile(df)
      #  if not_empty?(df) and File.exist?(df) 
      #    logfile[:dockerfile_signature] = [] if logfile[:dockerfile_signature].nil?
      #    d = digest_file(df)
      #    if not logfile[:dockerfile_signature].include?(d)
      #      logfile[:dockerfile_signature] << digest.hexdigest(File.read(df))
      #    end
      #    write
      #  end
      #end

      def log_dockerfile_image(df, image)
        if not_empty?(df) and File.exist?(df) and not_empty?(image)
          logfile[:dockerfile_images] = {  } if logfile[:dockerfile_images].nil?
          d = digest_file(df)
          logfile[:dockerfile_images][d] = [] if logfile[:dockerfile_images][d].nil?
          logfile[:dockerfile_images][d] << image
          write
        end
      end

      def has_dockerfile_built_to_image?(df)
        if not_empty?(df) 
          if File.exist?(df) 
            d = digest_file(df)
          else
            d = df
          end

          not (logfile[:dockerfile_images].nil? or logfile[:dockerfile_images][d].nil?)
        end
      end

      def dockerfile_images(df)
        if File.exist?(df)
          d = digest_file(df)
        else
          d = df
        end

        if (logfile[:dockerfile_images].nil? or logfile[:dockerfile_images][d].nil?)
          []
        else
          logfile[:dockerfile_images][d]
        end
      end

      def has_dockerfile_seen_before?(df)
        logger.debug "dockerfile_seen_before? #{df}"
        if not_empty?(df) and File.exist?(df) 
          d = Cli.digest_bin(File.read(df))
          logger.debug "Digest : #{d}"
          logger.debug "Record : #{logfile[:dockerfile_images]}"
          if not logfile[:dockerfile_images].nil?
            logfile[:dockerfile_images].include?(d)
          else
            false
          end
        else
          false
        end
      end

      def digest_file(path)
        if not_empty?(path) and File.exist?(path)
          Cli.digest_bin(File.read(path))
        else
          ""
        end
      end

      def image_has_containers?(image)
        not logfile[image].nil? and logfile[image].length > 0
      end

      def delete_image(image, opts = {})
        if logfile[image].nil? or is_empty?(logfile[image])
          logfile.delete(image)
        elsif not_empty?(opts) and opts[:force] == true
          logfile.delete(image)
        else
          raise NonEmptyRecord, "Image #{image} has #{logfile[image].length} container(s). Remove image failed."
        end
      end

      def update_last_run(image, cont)
        if not logfile[image].nil? and not logfile[image][cont].nil?
          logfile[image][cont][:last_run] = Time.now.to_i
          write
        end
      end

      def image_containers(image)
        if not logfile[image].nil?
          logfile[image]
        else
          []
        end
      end

      def all_logs
        logfile.freeze
      end

      private 
      def logfile
        if @_logfile.nil?
          if File.exist?(log_path)
            @_logfile = YAML.load(File.read(log_path))
          else
            @_logfile = {}
          end
        end
        @_logfile
      end

      def write
        File.open(log_path,"w") do |f|
          f.write YAML.dump(logfile)
        end
      end

      def log_path
        if @_logPath.nil?
          @_logPath = File.join(Dir.getwd, ".docker_run_log")
        end
        @_logPath
      end

      def digest
        if @_digest.nil?
          @_digest = Cli.digest
        end
        @_digest
      end

      def logger
        if @_logger.nil?
          @_logger = Cli.logger(:drLog)
        end
        @_logger
      end

    end # class DockerRunLog
  end
end
