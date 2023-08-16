
require 'tty/prompt'
require_relative '../docker_run_log'

module Docker
  module Cli
    module Operations
      class RunKeep
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

          opt "-n", "Name of the container" do |a|
            capture_container_name(a)
          end

          callback :post_processing do |a|
            run
          end

        end

        def initialize
          @match_user = false #TR::RTUtils.on_linux? 
          # leave this blank as the image may have already
          # set an entry program
          @cmd = ""
        end

        def capture_image(a)
          @fullArgv = a
          @dimage = a.first
          [true, a[1..-1]]
        end

        def capture_command(a)
          logger.debug "Capturing command : #{a}"
          @cmd = a 
        end

        def capture_container_name(a)
          @contName = a
        end

        def set_use_same_user(bol)
          @match_user = bol
        end
        
        # Just run with image name on command line
        def run

          if Docker::Cli::DockerRunLog.instance.has_existing_container?(@dimage)
            pmt = TTY::Prompt.new
            begin
              eCont = pmt.select(" System found there were some container already exist on this image.\n Do you want to reuse the existing container? ") do |m|
                DockerContainer.containers_of_image_from_history(@dimage).each do |c, name|
                  m.choice name, c
                end
                m.choice "Run new container", :new_cont
                m.choice "Quit", :quit
              end

              case eCont
              when :new_cont
                run_new
              when :quit
                STDOUT.puts " Have a nice day "
              else
                cont = DockerContainer.new(eCont)
                cont.start if not cont.is_running?
                cont.attach
              end
            rescue TTY::Reader::InputInterrupt
            end
          else
            run_new
          end

        end

        private
        def run_new
          mountLocal = Dir.getwd
          mountDocker = "/opt/#{File.basename(Dir.getwd)}"
          contName = @contName || SecureRandom.hex(18)
          if TR::RTUtils.on_linux? and @match_user
            # This approach has user match with local user but no name on the docker
            # workable not nice only
            Docker::Cli::DockerContainer.create_container(@dimage, interactive: true, tty: true, command: @cmd, mount: { mountLocal => mountDocker }, match_user: @match_user, container_name: contName)
          else
            # Apparently on Mac and Windows, the user issue is not an issue
            Docker::Cli::DockerContainer.create_container(@dimage, interactive: true, tty: true, command: @cmd, mount: { mountLocal => mountDocker }, container_name: contName)
          end

          Docker::Cli::DockerRunLog.instance.log(@dimage, contName, argv: @fullArgv)

        end

        def logger
          Cli.logger(:rk)
        end

      end
    end
  end
end
