

module Docker
  module Cli
    module ImageHelper
     
      def build_image(pmt, cmdFact)
        
        root = Dir.getwd
        dockerfile = File.join(root, "Dockerfile")

        again = true
        while again
          if not File.exist?(dockerfile)
            dockerfile = pmt.ask(" #{dockerfile} does not exist. Please provide new location of Dockerfile: ", required: true) 
          else
            again = false
          end
        end

        again = true
        while again
          dname = pmt.ask(" Please provide name of image at local : ", required: true)
          if cmdFact.is_image_exist?(dname)
            
            reuse = pmt.yes?(" Given local image name '#{dname}' already taken. Use back the same image? 'No' to retry with new name : ")
            if reuse 
              again = false
            end
          else
            rv = cmdFact.build_image(dname, dockerfile: dockerfile)
            raise CommandFailed, "Build image command failed. Error was : #{rv.err_stream}"
            again = false
          end
        end

        dname

      end

    end
  end
end
