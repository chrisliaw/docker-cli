
require 'yaml'

require_relative 'user_info'

module Docker
  module Cli
    class DockerComposer
      include TR::CondUtils
      include TR::ArgUtils

      arg_spec do

        callback :pre_processing do |a|
          parse_input(a)
        end

      end

      def parse_input(argv, &block)
        @dcPath = argv.first
        @dcPath = "./docker-compose.yml" if is_empty?(@dcPath) 
        @dcPath = "./docker-compose.yaml" if not File.exist?(@dcPath)
        raise RuntimeException, "docker-compose.[yml,yaml] not found. Please provide the docker-compose.yml file to load" if not File.exist?(@dcPath)

        @outPath = argv[1]
        @outPath = "#{@dcPath}-gen.yml" if is_empty?(@outPath)

        process_dc

        [true, []]
      end

      def process_dc
        if File.exist?(@dcPath)

          cont = YAML.safe_load(File.read(@dcPath))

          if not_empty?(cont["services"])

            cont["services"].each do |servName, conf|

              # if user key is empty, match with current uid and gid
              if conf.keys.include?("user") and is_empty?(conf["user"])
                conf["user"] = "#{user_info[:uid]}:#{user_group_info[:gid]}"
              end

              # add to volumes if there is development gems found
              if not_empty?(conf["volumes"])
                vol = conf["volumes"]

                if vol.include?("devgems")

                  vol.delete("devgems")
                  logger.debug "Volume after delete : #{vol.inspect}"

                  devGems = Cli.find_dev_gems
                  logger.debug " Found #{devGems.length} devgems"
                  if devGems.length > 0
                    if @parse_argv_block
                      @mount_root = @parse_argv_block.call(:prompt_docker_mount_root)
                    else
                      raise RuntimeException, "Please provide a block to prompt for missing parameters"
                    end

                    devGems.each do |name,path|
                      vol << "#{path}:#{File.join(@mount_root, name)}"
                    end
                  end

                end

              end
            end

          end

          reCont = cont.to_yaml
          reCont = reCont.gsub("---","")
          File.open(@outPath, "w") do |f|
            f.write reCont
          end

        else
          raise RuntimeException, "Given docker compose file '#{@dcPath}' does not exist"
        end
      end

      private
      def user_info
        if @_user_info.nil?
          @_user_info = UserInfo.user_info
        end
        @_user_info
      end

      def user_group_info
        if @_userg_info.nil?
          @_userg_info = UserInfo.group_info
        end
        @_userg_info
      end

      def logger
        if @_logger.nil?
          @_logger = Cli.logger(:docomp)
        end
        @_logger
      end

    end
  end
end
