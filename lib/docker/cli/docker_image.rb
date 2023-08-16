
require_relative 'command_factory'

module Docker
  module Cli
    class DockerImage
      include TR::CondUtils

      def self.set_master_format(format)
        @_doc_mformat = format
      end
      def self.master_format
        if @_doc_mformat.nil?
          @_doc_mformat = "{{.Repository}}#{self.separator}{{.ID}}#{self.separator}{{.Tag}}"
        end
        @_doc_mformat.freeze
      end

      def self.set_inspect_format(format)
        @_dec_iformat = format
      end
      def self.inspect_format
        if @_doc_iformat.nil?
          @_doc_iformat = "{{.Created}}#{self.separator}{{.Size}}"
        end
        @_doc_iformat.freeze
      end

      def self.set_separator(sep)
        @_doc_sep = sep
      end
      def self.separator
        if @_doc_sep.nil?
          @_doc_sep = ";"
        end
        @_doc_sep.freeze
      end

      def self.images
        logger.warn "loading images from system is an expensive operation. Please implement some cache at aplication level to increase its efficiency"
        cmd = []
        cmd << Cli.docker_exe
        cmd << "images"
        cmd << "--format"
        cmd << "\"#{self.master_format}\""

        rres = []
        res = Command.new(cmd).run
        if res.successful?
          res.each_line do |l|
            sp = l.strip.split(self.separator)
            rres << { name: sp[0], id: sp[1], tag: sp[2] }
          end
        else
          logger.warn "Command '#{cmd.join(" ")}' failed.\n Error was : #{res.err_stream}"
        end

        fres = []
        rres.each do |r|
          ccmd = []
          ccmd << cmd[0]
          ccmd << "inspect"
          ccmd << "-f"
          ccmd << "'{{.ID}}#{self.separator}{{.Created}}#{self.separator}{{.Size}}'"
          ccmd << r[:name]

          rres = Command.new(ccmd).run
          if rres.successful?
            rres.each_line do |l|
              sp = l.strip.split(self.separator)
              rid = sp[0]
              r[:image_id] = rid.split(":")[1]
              r[:created] = sp[1]
              r[:size] = sp[2]
              r[:runtime] = true
              fres << DockerImage.new(r[:name], r)
            end
          else
            logger.warn "Command '#{ccmd.join(" ")}' failed.\n Error was : #{rres.err_stream}"
          end
        end

        fres
      end

      def self.image(image)
        cmd = []
        cmd << Cli.docker_exe
        cmd << "images"
        cmd << "--format"
        cmd << "\"#{self.master_format}\""
        # image and tag is in single unit
        # e.g.:
        # jruby:9.2-jdk11
        # jruby:9
        # jruby:9.3.0.0-jdk11
        cmd << image

        rres = []
        res = Command.new(cmd).run
        if res.successful?
          # single image could have many lines because they have 
          # different tags!
          res.each_line do |l|
            sp = l.strip.split(self.separator)
            rres << { name: sp[0], id: sp[1], tag: sp[2] }
          end
        else
          logger.warn "Command '#{cmd.join(" ")}' failed.\n Error was : #{res.err_stream}"
        end

        fres = []
        rres.each do |r|
          ccmd = []
          ccmd << cmd[0]
          ccmd << "inspect"
          ccmd << "-f"
          ccmd << "'{{.ID}}#{self.separator}{{.Created}}#{self.separator}{{.Size}}'"
          ccmd << r[:name]

          rres = Command.new(ccmd).run
          if rres.successful?
            rres.each_line do |l|
              sp = l.strip.split(self.separator)
              rid = sp[0]
              r[:image_id] = rid.split(":")[1]
              r[:created] = sp[1]
              r[:size] = sp[2]
              r[:runtime] = true
              fres << DockerImage.new(r[:name], r)
            end
          else
            logger.warn "Command '#{ccmd.join(" ")}' failed.\n Error was : #{rres.err_stream}"
          end
        end

        fres
      end

      def self.build(imageName, dockerfile, context = ".")
        command.build_image(imageName, dockerfile: dockerfile, context_root: context).run
      end


      attr_reader :name, :tag, :size, :created, :image_id, :sid

      def initialize(name, opts = {})
        @name = name
        if not_empty?(opts)
          @sid = opts[:sid]
          @image_id = opts[:image_id]
          @tag = opts[:tag]
          @size = opts[:size]
          @created = opts[:created]
          @runtime = opts[:runtime]
        end

        @runtime = false if is_empty?(@runtime) or not_bool?(@runtime)

      end

      def is_runtime_image?
        @runtime
      end

      def has_containers?
        DockerRunLog.instance.image_has_containers?(@name)
      end

      def containers
        if @_cont.nil?
          # here assuming every run from system will be logged
          # but what about the one not using the system?
          @_cont = DockerRunLog.instance.image_containers(@name).collect { |e| DockerContainer.new(e[:container], e) }
        end
        @_cont
      end

      def delete!
        if not_empty?(@tag)
          command.delete_image(@name, @tag, opts)
        else
          raise IndefiniteOption, "Delete image cannot proceed because there might be more than single instance of the image. Please provide a tag for definite selection for deletion." 
        end
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

      def self.logger
        Cli.logger(:docker_image)
      end

    end
  end
end
