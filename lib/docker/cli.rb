# frozen_string_literal: true

require 'toolrack'
require 'teLogger'

require 'ptools'

require_relative "cli/version"
require_relative 'cli/command'
require_relative 'cli/command_factory'

module Docker
  module Cli
    class Error < StandardError; end
    # Your code goes here...
  
    def Cli.docker_exe

      path = File.which("docker")
      if path.nil?
        "docker"
      else
        path
      end

    end

  end
end
