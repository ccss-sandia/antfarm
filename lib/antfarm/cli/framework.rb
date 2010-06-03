require 'antfarm/framework'

module Antfarm
  module CLI
    class Framework < Antfarm::Framework
      def console(opts = Array.new)
        Antfarm::CLI::Console.new(opts)
      end

      def show
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
    end
  end
end
