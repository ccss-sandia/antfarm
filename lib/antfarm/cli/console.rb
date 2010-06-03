module Antfarm
  module CLI
    class Console
      def initialize(opts = [])
        if opts.include? '-h'
          puts <<-EOS

  The Antfarm Console drops the user into an interactive Ruby shell (irb)
  with access to all the Antfarm model classes.

          EOS
        else
          options = { :irb => 'irb' }

          libs =  " -r irb/completion"
          libs << %( -r "#{ANTFARM_ROOT}/config/environment")

          puts "Loading #{ENV['ANTFARM_ENV']} environment"
          puts

          exec "#{options[:irb]} #{libs} --simple-prompt"
        end
      end
    end
  end
end
