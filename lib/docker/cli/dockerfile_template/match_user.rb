
require 'erb'
require_relative '../user_info'

module Docker
  module Cli
    module DockerfileTemplate
      module MatchUser
        
        # DSL entry
        def match_user

          logger.debug "match_user called"
          ui = UserInfo.user_info
          gi = UserInfo.group_info

          ERB.new(user_template).result_with_hash({ user_group_id: gi[:gid], user_group_name: gi[:group_name], user_id: ui[:uid], user_login: ui[:login] })
           
        end

        private
        def user_template
          if @_ut.nil?
            @_ut = []
            @_ut << "RUN apt-get install -y sudo && groupadd -f -g <%= user_group_id %>  <%= user_group_name %> && useradd -u <%= user_id %> -g <%= user_group_id %> -m <%= user_login %> && usermod -aG sudo <%= user_login %> && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
            @_ut << "USER <%= user_login %>"
          end
          @_ut.join("\n")
        end

        def logger
          Cli.logger(:temp_match_user)
        end

      end
    end
  end
end
