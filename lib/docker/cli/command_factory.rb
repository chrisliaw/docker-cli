
require 'erb'

require_relative 'command'
require_relative 'user_info'

module Docker
  module Cli
    class CommandFactory
      include TR::CondUtils

      def build_image(name = "", opts = {  }, &block)

        opts = {  } if opts.nil?
        cmd = []
        cmd << Cli.docker_exe
        cmd << "build"
        if not_empty?(name)
          cmd << "-t #{name}"
        end

        if not_empty?(opts[:dockerfile])
          cmd << "-f #{opts[:dockerfile]}"
        end

        root = opts[:context_root]
        root = "." if is_empty?(root)
        cmd << root

        logger.debug "Build Image : #{cmd.join(" ")}"
        Command.new(cmd)

      end # build_image


      def find_image(name, tag = "", opts = { })
        name = "" if name.nil?
        cmd = []
        cmd << Cli.docker_exe
        cmd << "images"
        cmd << "-q"
        if not_empty?(tag)
          cmd << "\"#{name}:#{tag}\""
        else
          cmd << "\"#{name}\""
        end

        logger.debug "Find image: #{cmd.join(" ")}"

        Command.new(cmd)
      end # find_image

      def delete_image(name, tag = "", opts = { })

        if not_empty?(name)

          cmd = []
          cmd << Cli.docker_exe
          cmd << "rmi"
          if not_empty?(tag)
            cmd << "#{name}:#{tag}"
          else
            cmd << name
          end

          logger.debug "Delete image: #{cmd.join(" ")}"
          Command.new(cmd)

        else
          raise Error, "Name is required for delete operation"
        end

      end # delete_image


      def find_running_container(name, opts = { })

        raise Error, "Name is mandatory" if is_empty?(name)     

        cmd = []
        cmd << Cli.docker_exe
        cmd << "ps"
        cmd << "-q"
        cmd << "-f"
        
        if opts[:exact_name] == true
          cmd << "name=\"^/#{name}$\""
        else
          cmd << "name=\"#{name}\""
        end

        logger.debug "Find container: #{cmd.join(" ")}"

        Command.new(cmd)
       
      end

      # Find from container even if it is already stopped
      def find_from_all_container(name, opts = { })
        raise Error, "Name is required" if is_empty?(name)     
        cmd = []
        cmd << Cli.docker_exe
        cmd << "ps"
        # return all info instead of only the container ID
        #cmd << "-a"
        cmd << "-aq"
        cmd << "-f"
        # From little testing seems the command by default already support regex formatting
        # So can use the regex marker to get exact match
        # e.g. if want exact match, pass in ^#{name}\z
        #cmd << "name=\"#{name}\""

        if opts[:exact_name] == true
          cmd << "name=\"^/#{name}$\""
        else
          cmd << "name=\"#{name}\""
        end

        logger.debug "Find from all container: #{cmd.join(" ")}"
        Command.new(cmd)
      end

      # 
      # Create container from image directly
      # e.g. > docker run -it <image> "/bin/bash"
      #
      def create_container_from_image(image, opts = { })
        opts = {} if opts.nil?
        cmd = []
        cmd << Cli.docker_exe
        cmd << "run"
        cmd << "-i" if opts[:interactive] == true
        cmd << "-t" if opts[:tty] == true
        cmd << "-d" if opts[:detached] == true
        cmd << "--rm" if opts[:del] == true
        if not (opts[:container_name].nil? or opts[:container_name].empty?)
          cmd << "--name \"#{opts[:container_name]}\""
        end

        cmd << process_mount(opts)
        cmd << process_port(opts)
        cmd << process_network(opts)

        if opts[:match_user] == true
          ui = UserInfo.user_info
          gi = UserInfo.group_info
          cmd << "-u #{ui[:uid]}:#{gi[:gid]}"
        end

        cmd << image

        if not_empty?(opts[:command])
          #cmd << "\"#{opts[:command]}\""
          cmd << opts[:command]
        end

        interactive = false
        interactive = true if opts[:interactive] or opts[:tty]

        logger.debug "Run Container from Image : #{cmd.join(" ")}"
        Command.new(cmd, (interactive ? true : false))
      end # run_container_from_image

      def start_container(container, opts = { })

        opts = {} if opts.nil?
        cmd = []
        cmd << Cli.docker_exe
        cmd << "container"
        cmd << "start"
        cmd << container

        logger.debug "Start Container : #{cmd.join(" ")}"
        Command.new(cmd)
      end

      def attach_container(container, opts = { })

        opts = {} if opts.nil?
        cmd = []
        cmd << Cli.docker_exe
        cmd << "container"
        cmd << "attach"
        cmd << container

        logger.debug "Attach Container : #{cmd.join(" ")}"
        # this is a bit difficult to juggle 
        # it depending on the previous docker configuration
        # but to be save, just open up a new terminal
        Command.new(cmd, true)
      end
      
      
      def stop_container(container, opts = { })

        cmd = []
        cmd << Cli.docker_exe
        cmd << "container"
        cmd << "stop"
        cmd << container

        logger.debug "Stop Container : #{cmd.join(" ")}"
        Command.new(cmd)
      end

      
      def delete_container(container, opts = { })

        cmd = []
        cmd << Cli.docker_exe
        cmd << "container"
        cmd << "rm"
        cmd << container

        logger.debug "Delete Container : #{cmd.join(" ")}"
        Command.new(cmd)
      end


      def run_command_in_running_container(container, command, opts = {  })
        cmd = []
        cmd << Cli.docker_exe
        cmd << "container"
        cmd << "exec"

        isTty = false
        isInteractive = false
        if not_empty?(opts[:tty]) and opts[:tty] == true
          cmd << "-t" 
          isTty = true
        end
        if not_empty?(opts[:interactive]) and opts[:interactive] == true
          cmd << "-i" 
          isInteractive = true
        end

        cmd << container

        if is_empty?(command)
          cmd << "/bin/bash --login"
        else
          cmd << command
        end

        logger.debug "Run command in running container : #{cmd.join(" ")}"
        Command.new(cmd, ((isTty or isInteractive) ? true : false))
      end # container_prompt


      private
      # expecting :mounts => { "/dir/local" => "/dir/inside/docker" }
      def process_mount(opts)
        if not_empty?(opts[:mounts]) #not (opts[:mounts].nil? or opts[:mounts].empty?)
          m = opts[:mounts]
          if m.is_a?(Hash)
            res = []
            m.each do |local, docker|
              res << "-v #{local}:#{docker}"
            end
            res.join(" ")
          end
        else
          ""
        end
        
      end # process_mount

      def process_port(opts)
         if not_empty?(opts[:ports]) #not (opts[:ports].nil? or opts[:ports].empty?)
          po = opts[:ports]
          res = []
          if po.is_a?(Hash)
            po.each do |host, docker|
              res << "-p #{host}:#{docker}"
            end
          end
          #po = [po] if not po.is_a?(Array)
          #po.each do |e|
          #  # 1st is port on host
          #  # 2nd is port inside container
          #  res << "-p #{e.keys.first}:#{e.values.first}"
          #end
          res.join(" ")
        else
          ""
        end
        
      end

      def process_network(opts)
        if not_empty?(opts) and not_empty?(opts[:network])
          "--network=#{opts[:network]}" 
        else
          "" 
        end
      end

      def logger
        Cli.logger(:cmdFact)
      end

      def build_add_user_script
        path = File.join(File.dirname(__FILE__),"..","..","..","scripts","create_user.sh.erb")
        if File.exist?(path)
          ui = UserInfo.user_info
          gi = UserInfo.group_info

          ERB.new(File.read(path)).result_with_hash({ user_group_id: gi[:gid], user_group_name: gi[:group_name], user_id: ui[:uid], user_login: ui[:login] })
        end
      end

    end
  end
end
