
require_relative '../../lib/docker/cli/dockerfile_template'

RSpec.describe "Dockerfile Template" do 

  it 'renders the match_user instruction' do
  
    cont = "<%= match_user %>"

    res = Docker::Cli::DockerfileTemplate::TemplateEngine.new.process(cont)

    ui = Docker::Cli::UserInfo.user_info
    gi = Docker::Cli::UserInfo.group_info

    p res
    expect((res =~ /#{ui[:user_login]}/) != nil).to be true

  end

  it 'renders the dup_gem_bundler_env instruction' do
    cont = %Q(
      <%= dup_gem_bundler_env %>
    )

    expect {
      Docker::Cli::DockerfileTemplate::TemplateEngine.new.process(cont)
    }.to raise_exception(Docker::Cli::DockerfileTemplate::TemplateKeyRequired)

    res = Docker::Cli::DockerfileTemplate::TemplateEngine.new.process(cont, { docker_root: "/opts" })
    p res
    p File.read("dup_gem_bundler_env.rb")

  end

end
