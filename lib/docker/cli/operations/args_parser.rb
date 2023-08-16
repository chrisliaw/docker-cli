
require 'toolrack'
require_relative 'run_keep'
require_relative 'run_del'
require_relative 'run'

module Docker
  module Cli
    class ArgsParser
      include TR::ArgUtils

      class ArgsParserException < StandardError; end

      OpsOption = [
        "run-keep", "rk",
        "run-del","rd",
        "run","r"
      ]

      arg_spec do 
        
        callback :pre_processing do |argv|
          select_runner(argv)
        end

      end

      def select_runner(argv)
        ops = argv.first
        if is_empty?(ops)
          raise ArgsParserException, "\n Operation is empty. First parameter is operation. Supported operations including : #{OpsOption.join(", ")}\n\n"
        else
          case ops
          when "run-keep", "rk" 
            Docker::Cli::Operations::RunKeep.new.parse_argv(argv[1..-1])

          when "run-del", "rd"
            Docker::Cli::Operations::RunDel.new.parse_argv(argv[1..-1])

          when "run", "r"
            Docker::Cli::Operations::Run.new.run

          else
            raise ArgsParserException, " Unknown operation '#{ops}'. First parameter is operation. Supported operations including : #{OpsOption.join(", ")}\n" 
          end
        end

        [true, argv[1..-1]]
      end

    end
  end
end
