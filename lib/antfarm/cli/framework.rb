################################################################################
#                                                                              #
# Copyright (2008-2010) Sandia Corporation. Under the terms of Contract        #
# DE-AC04-94AL85000 with Sandia Corporation, the U.S. Government retains       #
# certain rights in this software.                                             #
#                                                                              #
# Permission is hereby granted, free of charge, to any person obtaining a copy #
# of this software and associated documentation files (the "Software"), to     #
# deal in the Software without restriction, including without limitation the   #
# rights to use, copy, modify, merge, publish, distribute, distribute with     #
# modifications, sublicense, and/or sell copies of the Software, and to permit #
# persons to whom the Software is furnished to do so, subject to the following #
# conditions:                                                                  #
#                                                                              #
# The above copyright notice and this permission notice shall be included in   #
# all copies or substantial portions of the Software.                          #
#                                                                              #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR   #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,     #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  #
# ABOVE COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, #
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR #
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE          #
# SOFTWARE.                                                                    #
#                                                                              #
# Except as contained in this notice, the name(s) of the above copyright       #
# holders shall not be used in advertising or otherwise to promote the sale,   #
# use or other dealings in this Software without prior written authorization.  #
#                                                                              #
################################################################################

require 'antfarm/framework'

module Antfarm
  module CLI
    class Framework < Antfarm::Framework
      def version(opts = Array.new)
        if opts.include?('-h')
          puts <<-EOS

  The Antfarm 'version' command simply displays what version of the Antfarm
  command line interface and Antfarm core are currently in use.

  Because of its simplicity, we went ahead and ran it for you... see below.
          EOS
        end

        puts
        puts "  Antfarm Command-Line Interface: Version #{Antfarm::CLI.version}"
        puts "  Antfarm Core: Version #{Antfarm.version}"
        puts
      end

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

  Because of its simplicity, we went ahead and ran it for you... see below.

          EOS
        end

        table        = Antfarm::CLI::UI::Console::Table.new
        table.header = ['Plugin Name', 'Plugin Description']

        plugins.each do |name,plugin|
          table.add_row([name, plugin.info[:desc]])
        end

        table.print
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
