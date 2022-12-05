# frozen_string_literal: true

RSpec.describe Docker::Cli do
  it "has a version number" do
    expect(Docker::Cli::VERSION).not_to be nil
  end

  it 'manages docker' do
    cf = Docker::Cli::CommandFactory.new 
    cmd = cf.build_image("cli-test", dockerfile: "Dockerfile.cli.test")

    begin
      
      res = cmd.run 
      expect(res[:result].failed?).to be false
     
      res = cf.find_image("cli-test").run
      expect(res[:result].failed?).to be false
      expect(res[:outStream].empty?).to be false
      puts res[:outStream]

      res = cf.find_from_all_container("cli-test-container").run
      expect(res[:result].failed?).to be false

      if not res[:outStream].empty?
        # container already created
        res = cf.find_running_container("cli-test-container").run
        if res[:outStream].empty?
          # not running
          res = cf.start_container("cli-test-container").run
          expect(res[:result].failed?).to be false
        end

        cf.run_command_in_running_container("cli-test-container", "/bin/bash", tty: true, interactive: true ).run

      else

        res = cf.create_container_from_image("cli-test", interactive: true, tty: true, container_name: "cli-test-container" ).run
      end

    rescue TTY::Command::ExitError => e
      p e
    end

  end
end
