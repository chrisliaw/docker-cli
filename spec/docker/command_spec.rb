

RSpec.describe "Docker::Cli::Command" do

  it 'creates new terminal and run command from it' do
   
    Docker::Cli::Command.new(["pwd"], true).run 

  end

end
