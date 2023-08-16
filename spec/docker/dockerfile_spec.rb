
require_relative '../../lib/docker/cli/dockerfile'

RSpec.describe "Generate dockerfile from template" do

  it 'generates final Dockerfile' do
    
    df = Docker::Cli::Dockerfile.new("Dockerfile")
    # key inside the last parameter is depending on Dockerfile entry
    file = df.to_dockerfile(dockerRoot: "/opt/project")
    puts File.read(file)

  end

end
