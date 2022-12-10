
require 'tty/command'
require 'tty/prompt'
require 'ptools'

require_relative 'command_result'

module Docker
  module Cli
    class Command
      include TR::CondUtils

      attr_accessor :command_buffer
      def initialize(cmd, required_interaction = false)
        @command_buffer = cmd
        @runner = TTY::Command.new
        @required_interaction = required_interaction
        @required_interaction = false if not_bool?(@required_interaction)
      end

      def interactive_session?
        @required_interaction
      end

      def run(&block)

        if interactive_session?
          
          pmt = TTY::Prompt.new
          terminal = pmt.select "Command is an interactive command. New terminal session is required. Please select one of the session below to proceed:" do |m|
            detect_terminal.each do |t|
              m.choice t, t
            end

            m.choice "Quit", :quit
          end

          if terminal != :quit
            case terminal
            when "terminator"
              `#{terminal} -x "#{@command_buffer.join(" ")}"`
            when "gnome-terminal"
              `#{terminal} -- bash -c "#{@command_buffer.join(" ")}; exec bash"`
            else
              raise Error, "Unfinished supporting terminal : #{terminal}"
            end
          end

        else
          @outStream = []
          @errStream = []
          @result = @runner.run!(@command_buffer.join(" "))  do |out, err|
            if block
              block.call(:outstream, out)
              block.call(:errstream, err)
            else
              @outStream << out if not_empty?(out)
              @errStream << err if not_empty?(err)
            end
          end

          CommandResult.new(@result, @outStream, @errStream)
          #{ outStream: @outStream, errStream: @errStream, result: @result }
        end
      end

      def to_string
        @command_buffer
      end

      private
      def detect_terminal
        possible = [ "gnome-terminal","konsole","cmd.exe", "tilix", "terminator" ]
        avail = []
        possible.each do |app|
          avail << app if not File.which(app).nil?
        end
        avail
      end

    end
  end
end
