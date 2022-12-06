

module Docker

  module Cli
    
    class CommandResult
      include TR::CondUtils

      attr_reader :out, :err, :result
      def initialize(result, out, err)
        @result = result
        @out = out
        @err = err
      end

      def is_out_stream_empty?
        is_empty?(@out)
      end

      def out_stream
        @out.join("\n") 
      end

      def err_stream
        @err.join("\n")
      end

      def failed?
        if @result.nil?
          true
        else
          @result.failed?
        end
      end

    end

  end
  
end
