
module Docker
  module Cli
    module Operations
      class RunDel
        include TR::ArgUtils

        arg_spec do

          callback :pre_processing do |a|
            capture_image(a)
          end

          opt "-c", "Command to be executed inside the Docker" do |a|
            capture_command(a)
          end

          opt "-u", "Run as current user for Docker" do
            set_use_same_user(true)
          end

          callback :post_processing do |a|
            run
          end

        end

        def initialize
          @match_user = false 
          # leave this blank as the image may have already
          # set an entry program
          @cmd = ""
        end

        def capture_image(a)
          @dimage = a.first
          [true, a[1..-1]]
        end

        def capture_command(a)
          @cmd = a 
        end

        def set_use_same_user(bol)
          @match_user = bol
        end

        # Just run with image name on command line
        def run

          mountLocal = Dir.getwd
          mountDocker = "/opt/#{File.basename(Dir.getwd)}"
          if TR::RTUtils.on_linux? and @match_user
            # This approach has user match with local user but no name on the docker
            # workable not nice only
            Docker::Cli::DockerContainer.create_container(@dimage, interactive: true, tty: true, command: @cmd, mount: { mountLocal => mountDocker }, match_user: @match_user, del: true)
          else
            # Apparently on Mac and Windows, the user issue is not an issue
            Docker::Cli::DockerContainer.create_container(@dimage, interactive: true, tty: true, command: @cmd, mount: { mountLocal => mountDocker }, del: true)
          end

        end

      end
    end
  end
end
