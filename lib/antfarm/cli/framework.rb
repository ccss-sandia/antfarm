require 'antfarm/framework'

module Antfarm
  module CLI
    class Framework < Antfarm::Framework
      def db(args)
        options = parse_db_options(args)
        if options[:clean]
          clean_db
        elsif options[:migrate]
          migrate_db
        elsif options[:reset]
          reset_db
        elsif options[:console]
          db_console
        end
      end

      def console(opts = Array.new)
        Antfarm::CLI::Console.new(opts)
      end

      def show(opts = Array.new)
        if opts.include?('-h')
          puts <<-EOS

  The Antfarm 'show' command simply lists all the plugins currently available to
  the user, along with a description of the plugin.

  Because of it's simplicity, we went ahead and ran it for you... see below.

          EOS
        end

        table        = Antfarm::CLI::UI::Console::Table.new
        table.header = ['Plugin Name', 'Plugin Description']

        plugins.each do |name,plugin|
          table.add_row([name, plugin.info[:desc]])
        end

        return table.print
      end

      # TODO: <scrapcoder> - throw error if @plugin is nil
      def show_info
        Antfarm::CLI::Plugin.show_info(@plugin)
      end

      # TODO: <scrapcoder> - throw error if @plugin is nil
      def show_options
        Antfarm::CLI::Plugin.show_options(@plugin)
      end

      #######
      private
      #######

      def parse_db_options(args)
        args << '-h' if args.empty?

        return Trollop::options(args) do
          banner <<-EOS

Antfarm Database Manager

Options:
          EOS
          opt :clean,   "Clean application's environment (REMOVE ALL!)"
          opt :migrate, 'Migrate tables in database'
          opt :reset,   'Reset tables in database and clear log file for given environment (clean + migrate)'
          opt :console, 'Start up relevant database console using database for given environment'
        end
      end

      def db_console
        config = YAML::load(IO.read(Antfarm::Helpers.defaults_file))
        puts "Loading #{ANTFARM_ENV} environment"

        if config && config[ANTFARM_ENV] && config[ANTFARM_ENV]['adapter'] == 'postgres'
          exec "psql #{ANTFARM_ENV}"
        else
          exec "sqlite3 #{Antfarm::Helpers.db_file(ANTFARM_ENV)}"
        end
      end
    end
  end
end
