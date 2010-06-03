module Antfarm
  module CLI
    class Plugin
      DISPLAYED_OPTIONS = [:name, :desc, :type, :default, :required]

      def self.show_info(plugin)
        table        = Antfarm::CLI::UI::Console::Table.new
        table.header = ['Plugin Info', '']
        for key in Antfarm::Plugin::ALLOWED_INFO
          table.add_row([key.to_s.capitalize, plugin.info[key].to_s])
        end
        table.print
      end

      def self.show_options(plugin)
        table        = Antfarm::CLI::UI::Console::Table.new
        table.header = DISPLAYED_OPTIONS.map { |key| key.to_s.capitalize }
        for option in plugin.options
          row = DISPLAYED_OPTIONS.map { |key| key == :name ? "--#{option[key].to_s.gsub(/_/,'-')}" : option[key].to_s }
          table.add_row(row)
        end
        puts 'Plugin Options:'
        table.print
      end
    end
  end
end
