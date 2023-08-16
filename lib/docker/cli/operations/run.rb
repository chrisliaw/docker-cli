
require 'securerandom'
require 'tty/prompt'
require_relative '../dockerfile'

module Docker
  module Cli
    module Operations
     
      # Normal run by finding Dockerfile
      # By default is interactive
      class Run

        def initialize
          @pmt = TTY::Prompt.new
        end

        def run
         
          # find dockerfile to build an image
          df = Dockerfile.find_available
          raise NoDockerfileFound, "No Dockerfile found. Please create one and re-run this operation" if df.length == 0

          if df.length > 1
            @selDf = @pmt.select(" Please select one of the Dockerfile to execute : ") do |m|
              df.each do |f|
                m.choice f, f
              end
            end
          else
            @selDf = df.first
          end

          @mount_root = @pmt.ask(" Please provide a root for folder mount into Docker env : ", default: "/opt", required: true)

          df = Dockerfile.new(@selDf)
          # parameter pass in is to build the template
          # e.g. docker_root is to build the dup_gem_bundler_env directive
          ndf = df.render_dockerfile(docker_root: @mount_root)

          @dev_gems = {}
          devGems = Cli.find_dev_gems
          if devGems.length > 0
            devGems.each do |k,v|
              @dev_gems[v] = File.join(@mount_root, File.basename(v))
            end
          end

          dfName = @pmt.ask(" Please provide the new name for the generated Dockerfile : ", required: true, default: "Dockerfile.docli")
          dfPath = File.join(Dir.getwd, dfName)
          File.open(dfPath,"w") do |f|
            f.write ndf
          end

          if Dockerfile.run_before?(dfPath)
            proceed = @pmt.yes?(" Given dockerfile '#{@selDf}' seems already run before. Do you want to use existing image instead? ")
            if proceed
              img = Dockerfile.images(dfPath)
              if img.length > 1
                @selImg = @pmt.select(" There are multiple images being run from the same Dockerfile. Please select one of them : ") do |m|
                  img.each do |i|
                    m.choice i, i
                  end
                end
              elsif img.length > 0
                @selImg = img.first
              end

            else
              # not using existing image.. built one
              #@df, @selImg = build_image_from_dockerfile_bin(ndf)
              @selImg = build_image_from_dockerfile(dfPath, dfName)
            end

          else
            #logger.debug "Dockerfile not being run before"
            #@df, @selImg = build_image_from_dockerfile_bin(ndf)  # => 
            @selImg = build_image_from_dockerfile(dfPath, dfName)
          end

          logger.debug "selected image : #{@selImg}"

          di = DockerImage.new(@selImg)
          if di.has_containers?
            if di.containers.length > 1
              @selCont = @pmt.select(" Please select one of the container to run : ") do |m|

                di.containers.each do |c|
                  m.choice c.name_for_display, c
                end

                m.choice "New container", :new

              end

            else
              @selCont = di.containers.first
            end

          end # has_containers?


          case @selCont
          when :new, nil
            @selCont = @pmt.ask(" Please provide a new container name : ", required: true, default: "#{File.basename(Dir.getwd)}_#{SecureRandom.hex(4)}")

            cp = ContainerProfile.new 
            if devGems.length > 0
              devGems.each do |name, path|
                cp.add_mount_point(path, File.join(@mount_root, name))
              end
            end

            # add current dir as mount point
            cp.add_mount_point(Dir.getwd, File.join(@mount_root, File.basename(Dir.getwd)))

            while true
              STDOUT.puts "\n\n Mount points : \n"
              ctn = 1
              cp.mount_points.each do |local, docker|
                STDOUT.puts " #{ctn}. #{local} ==> #{docker}"
              end
              apath = @pmt.ask("\n Please provide full path to mount in the docker (just enter if done) : ")
              break if is_empty?(apath)

              if File.exist?(apath)
                mpath = @pmt.ask(" Please provide mount point inside the docker : ", default: File.dirname(apath))
                cp.add_mount_point(mpath, File.join(@mount_root, File.basename(mpath)))
              else
                STDERR.puts "Given path '#{apath}' doesn't exist. Please try again."
              end
            end

            cmd = @pmt.ask(" What command should be inside the docker? : ", required: true, default: "/bin/bash" )
            cp.run_command = cmd
            cp.image_name = @selImg

            dc = DockerContainer.new(@selCont)
            dc.create(cp)
            DockerRunLog.instance.log(@selImg, @selCont)

          else

            #cmd = @pmt.ask(" What command should be inside the docker? : ", required: true, default: "/bin/bash" )
            dc = DockerContainer.new(@selCont.name)
            dc.start
            dc.attach
            #dc.run(cmd)

          end


        end

        def build_image_from_dockerfile(df, dfName)

          iName = File.basename(Dir.getwd)
          name = @pmt.ask(" Please provide an image name for Dockerfile '#{dfName}' : ", required: true, default: "#{iName}_image") 
          ctx = @pmt.ask(" Context to run to the dockerfile? ", required: true, default: ".")

          DockerImage.build(name, dfName ,ctx)
          DockerRunLog.instance.log_dockerfile_image(df, name)

          name

        end

        #def build_image_from_dockerfile_bin(df)
        #  #raise NoDockerfileFound, "Given Dockerfile to build image '#{df}' does not exist" if not File.exist?(df)

        #  dfName = @pmt.ask(" Please provide the new name for the generated Dockerfile : ", required: true, default: "Dockerfile.docli")
        #  path = File.join(Dir.getwd, dfName)
        #  dfName = File.basename(path)
        #  if not_empty?(df)
        #    File.open(path,"w") do |f|
        #      f.write df
        #    end
        #  end
        # 
        #  iName = File.basename(Dir.getwd)
        #  name = @pmt.ask(" Please provide an image name for Dockerfile '#{dfName}' : ", required: true, default: "#{iName}_image") 
        #  ctx = @pmt.ask(" Context to run to the dockerfile? ", required: true, default: ".")

        #  DockerImage.build(name, dfName ,ctx)
        #  DockerRunLog.instance.log_dockerfile_image(df, name)

        #  [dfName, name]
        #end


        private
        def logger
          if @_logger.nil?
            @_logger = Cli.logger(:run_ops)
          end
          @_logger
        end

      end

    end
  end
end
