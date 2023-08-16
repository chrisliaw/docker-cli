
require_relative 'command_factory'

module Docker
  module Cli

    # only use during creation of new container
    class ContainerProfile
      include TR::CondUtils

      attr_accessor :run_command, :image_name
      def initialize
        @interactive = true
        @run_detached = false
        @remove_after_run = false
        @match_user = false
        @run_command = "/bin/bash"
        @mounts = {}
        @ports = {}
      end

      def mount_points
        @mounts.freeze
      end
      def add_mount_point(host, inside_docker)
        if not_empty?(host) and not_empty?(inside_docker)
          @mounts[host] = inside_docker
        end
      end

      def ports
        @ports.freeze
      end
      def add_port_mapping(host, docker)
        if not_empty?(host) and not_empty?(docker)
          @ports[host] = docker
        end
      end

      def is_interactive?
        @interactive
      end
      def interactive=(val)
        @interactive = val
      end

      def is_run_detached?
        @run_detached
      end
      def run_detached=(val)
        @run_detached = val
      end

      def remove_after_run?
        @remove_after_run
      end
      def remove_after_run=(val)
        @remove_after_run = val 
      end

      def is_match_user?
        @match_user
      end
      def match_user=(val)
        @match_user = val
      end

      def to_hash
        # this returns a hash that match expectation of input in CommandFactory.create_container_from_image
        { interactive: @interactive, tty: @interactive, detached: @run_detached, del: @remove_after_run, mounts: @mounts, ports: @ports, match_user: @match_user, command: @run_command }
      end

    end # class NewContainerProfile

    class DockerContainer
      include TR::CondUtils

      #def self.is_exists?(name)
      #  res = command.find_from_all_container(name, opts).run 
      #  raise CommandFailed, "Command to check if container exist failed. Error was : #{res.err_stream}" if not res.successful?
      #  not res.is_out_stream_empty?
      #end

      #def self.create(image, opts = {}, &block)
      #  command.create_container_from_image(image, opts).run
      #end

      #def self.prep_container(image, opts = {})
      #  # render the create_user script
      #  res = build_add_user_script
      #  # system always mount current dir inside docker
      #  dest = File.join(opts[:mount_local],"create_user.sh")
      #  File.open(dest,"w") do |f|
      #    f.write res
      #  end
      #  `chmod +x #{dest}`

      #  # create non interactive session to create the user & group first
      #  opts[:command] = "#{File.join(opts[:mount_docker],"create_user.sh")}"
      #  opts[:detached] = true
      #  command.create_container_from_image(image, opts).run
      #end

      def self.containers_of_image_from_history(img, opts = {  })
        cont = DockerRunLog.instance.containers(img)
        res = {}
        if cont.length == 1
          c = cont.first
          res[c[:container]] = c
        else
          cont.each do |c|
            res[c[:container]] = "#{c[:container]} [Last Access : #{Time.at(c[:last_run])}] - Config : #{c[:argv]}"
          end
          res
        end
      end

      #def self.containers(image = nil)
      #  
      #end

      #def self.container(name)
      #  
      #end

      attr_reader :name

      def initialize(name, history = nil)
        @name = name
        @history = history
      end

      def is_exist?
        res = command.find_from_all_container(@name).run 
        raise CommandFailed, "Command to check if container exist failed. Error was : #{res.err_stream}" if not res.successful?
        not res.is_out_stream_empty?
      end

      def create(container_profile)
        raise CommandFailed, " Image name is not given to create the container '#{@name}'" if is_empty?(container_profile.image_name)
        opts = container_profile.to_hash
        opts[:container_name] = @name
        command.create_container_from_image(container_profile.image_name, opts).run
      end

      def name_for_display
        if @history.nil?
          @name
        else
          "#{@history[:container]} [Last Access : #{Time.at(@history[:last_run])}] - Config : #{@history[:argv]}"
        end
      end

      def run_before?
        not @history.nil?
      end

      def history
        if not @history.nil?
          @history.freeze
        else
          @history = {}
        end
      end

      def is_running?
        res = command.find_running_container(@name).run
        raise CommandFailed, "Command to find running container failed. Error was : #{res.err_stream}" if not res.successful?
        not res.is_out_stream_empty?
      end

      def start(&block)
        command.start_container(@name).run
      end

      def stop(&block)
        command.stop_container(@name).run
      end

      def attach(&block)
        command.attach_container(@name).run
      end

      def delete!(&block)
        command.delete_container(@name).run
      end

      def run(cmd, opts = {}, &block)
        command.run_command_in_running_container(@name, cmd, opts).run 
      end

      private
      def self.command
        if @_cmd.nil?
          @_cmd = CommandFactory.new
        end
        @_cmd
      end

      def command
        self.class.command
      end

      def self.build_add_user_script
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
