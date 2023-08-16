
Dir.glob(File.join(File.dirname(__FILE__),"dockerfile_template","*.rb")).each do |f|
  require_relative f
end

module Docker
  module Cli
    module DockerfileTemplate
      class TemplateKeyRequired < StandardError; end
      class TemplateEngine
        include MatchUser
        include DupGemBundlerEnv

        def process(cont, values = {}, &block)
          logger.debug "Got values : #{values}"
          values.each do |k,v|

            logger.debug "Creating field #{k}"
            
            self.class.class_eval <<-END
            if not (Class.instance_methods.include?(:#{k}) and Class.instace_methods.include?(:#{k}=))
              attr_accessor :#{k}
            elsif not Class.instance_methods.include?(:#{k})
              attr_reader :#{k}
            elsif not Class.instance_methods.include?(:#{k}=)
              attr_writer :#{k}
            end
            END

            self.send("#{k}=", v)
          end


          ERB.new(cont).result(binding)
        end

        private 
        def logger
          if @_logger.nil?
            @_logger = Cli.logger(:df_template)
          end
          @_logger
        end

        def add_mandatory_key(key)
          if @_man.nil?
            @_man = []
          end
          @_man << key if not_empty?(key)
        end

        def mandatory_keys
          @_man
        end

        def has_mandatory_keys?
          given = true
          mandatory_keys.each do |mk|
            given = Class.instance_methods.include?(mk.to_sym) and Class.instance_methods.include?("#{mk}=".to_sym)
            break if not given
          end

          given
        end

      end
    end
  end
end
