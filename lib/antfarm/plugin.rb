module Antfarm
  @plugins = Hash.new

  class << self
    attr_accessor :plugins

    def register(plugin)
      Plugin.new.register(plugin)
    end

    def plugin(name)
      return plugins[name]
    end
  end

  class Plugin
    class NameException < Exception
      def initialize(klass)
        super "must provide a unique plugin name for '#{klass.name}'"
      end
    end

    class RegisteredOptionsException < Exception
      def initialize(name)
        super "no options registered for '#{name}'"
      end
    end

    class RegistrationException < Exception
      def initialize
        super "must implement the 'registered' method"
      end
    end

    class RuntimeOptionsException < Exception
      def initialize(name)
        super "missing options for '#{name}' at runtime"
      end
    end

    class RunMethodException < Exception
      def initialize
        super "must implement the 'run' method"
      end
    end
  end

  class Plugin
    # can use the 'options' attribute to build option parsers
    # in command-line interfaces... :-)
    attr_accessor :name, :info, :options, :plugin_module

    def initialize
      @name, @options, @plugin_module = String.new, Array.new, nil
    end

    def register(plugin)
      raise RegistrationException unless plugin.respond_to?(:registered)
      plugin.registered(self)
      raise NameException, plugin if @name.nil? or @name.empty? or Antfarm.plugins.key?(@name)
      extend plugin
      raise RunMethodException unless self.respond_to?(:run)
      # TODO: check options, if set, to ensure required keys and types are set for each
      @plugin_module = plugin # why do we have plugin_module?
      Antfarm.plugins[name] = self
      return self
    end

    #######
    private
    #######

    def check_options(opts)
      # fail if user provided options but plugin doesn't require any
      if @options.empty? and not opts.empty?
        raise RegisteredOptionsException, @name
      end

      # ensure all required options were provided by user, all options
      # provided by user are of the correct type, and options are within
      # acceptable list if provided
      @options.each do |option|
        if option[:required]
          unless opts.key?(option[:name].to_sym)
            if option.key?(:default)
              opts[option[:name].to_sym] = option[:default]
            else
              raise RuntimeOptionsException, @name
            end
          end
        end

        if opts.key?(option[:name].to_sym)
          if option.key?(:type)
            unless opts[option[:name].to_sym].is_a?(option[:type])
              raise "option '#{option[:name]}' must be of type '#{option[:type]}'"
            end

            if option.key?(:accept)
              unless option[:accept].include?(opts[option[:name].to_sym])
                raise "option '#{opts[option[:name].to_sym]}' not within acceptable list"
              end
            end
          end
        end
      end
    end
  end
end

Dir["#{Antfarm.root}/lib/antfarm/plugins/*.rb"].each  { |file| require file }
Dir["#{Antfarm::Helpers.user_plugins_dir}/*.rb"].each { |file| require file }
