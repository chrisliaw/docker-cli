

RSpec.describe Docker::Cli::DockerImage do

  it 'loads all current images into system' do
    
    i = Docker::Cli::DockerImage.images
    sel = i[rand(0...i.length)]
    si = Docker::Cli::DockerImage.image(sel.name)
    p si
    expect(si.first.is_runtime_image?).to be true

  end

end
