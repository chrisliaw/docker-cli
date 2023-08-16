# frozen_string_literal: true

require 'toolrack'
require 'teLogger'

require 'ptools'

require_relative "cli/version"
require_relative 'cli/command'
require_relative 'cli/command_factory'

require_relative 'cli/docker_image'
require_relative 'cli/docker_container'
require_relative 'cli/docker_composer'

require_relative 'cli/dockerfile_template'

module Docker
  module Cli
    include TR::CondUtils

    class Error < StandardError; end
    class RuntimeException < StandardError; end
    class CommandFailed < StandardError; end
    class IndefiniteOption < StandardError; end
    class NoDockerfileFound < StandardError; end
    # Your code goes here...
  
    def Cli.docker_exe

      path = File.which("docker")
      if path.nil?
        "docker"
      else
        path
      end

    end

    def self.find_dev_gems
      if @_devGems.nil?
        @_devGems = {}
        Bundler.load.dependencies.each do |d|
          if not d.source.nil?
            src = d.source
            if src.path.to_s != "."
              @_devGems[d.name] = src.path.expand_path.to_s
            end
          end
        end
      end
      @_devGems
    end

    def self.digest_bin(bin)
      OpenSSL::Digest.new("SHA3-256").hexdigest(bin)
    end

    def self.command_output(out)
      if out.is_a?(Array)
        out.each do |e|
          STDOUT.puts " ## #{e}"
        end
      else
        STDOUT.puts " ## #{out}"
      end
    end

    def self.logger(tag = nil, &block)
      if @_logger.nil?
        @_logger = TeLogger::Tlogger.new(STDOUT)
      end

      if block
        if not_empty?(tag)
          @_logger.with_tag(tag, &block)
        else
          @_logger.with_tag(@_logger.tag, &block)
        end
      else
        if is_empty?(tag)
          @_logger.tag = :docker_cli
          @_logger
        else
          # no block but tag is given? hmm
          @_logger.tag = tag
          @_logger
        end
      end
    end

  end
end
