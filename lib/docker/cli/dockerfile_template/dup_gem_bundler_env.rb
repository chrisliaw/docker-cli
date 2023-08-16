
module Docker
  module Cli
    module DockerfileTemplate
      module DupGemBundlerEnv
      
        # DSL entry by including into DockerfileTemplate module
        def dup_gem_bundler_env(&block)
          if has_dev_gems?
            logger.debug "Detected development gems"

            #add_mandatory_key(:docker_root)
            #if not has_mandatory_keys? and block
            #  @docker_root = block.call(:docker_root)
            #else
              raise TemplateKeyRequired, "docker_root is required for dup_gem_bundler_env to function" if is_empty?(@docker_root)
            #end

            # gen shell script
            res = gen_script
            block.call(:script_output, res) if block
            localPath = File.join(Dir.getwd,"dup_gem_bundler_env.rb")
            File.open(localPath,"w") do |f|
              f.write res
            end

            inst = []
            # copy inside docker
            inst << "COPY #{File.basename(localPath)} /tmp/dup_gem_bundler_env.rb"
            # run the script
            inst << "RUN ruby /tmp/dup_gem_bundler_env.rb"
            # for the docker just this two lines
            # but the localPath must be there first before this two
            # lines can come into effect
            inst.join("\n")
          else
            ""
          end
        end

        private
        def has_dev_gems?
          not Cli.find_dev_gems.empty? 
        end

        def gen_script

          res = %Q(
#!/usr/bin/env ruby

## This file is auto-generated.

<% Docker::Cli.find_dev_gems.each do |name, pa| %>
`bundle config --global local.<%= name %> <%= File.join(@docker_root, File.basename(pa)) %>`
<% end %>
          )

          ERB.new(res).result(binding)
           
        end

        def logger
          if @_logger
            @_logger = Cli.logger(:temp_dup_gem_bundler_env)
          end
          @_logger
        end
        

      end
    end
  end
end
