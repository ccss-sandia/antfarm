################################################################################
#                                                                              #
# Copyright (2008-2014) Sandia Corporation. Under the terms of Contract        #
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
              # TODO: add test for this...
              raise "option '#{option[:name]}' must be of type '#{option[:type]}'" if option[:required]
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

    # Handle the reading of data from files in a common way for all plugins.
    # My hope is that I can override this method in tests to provide custom
    # test data via StringIO objects... we'll see!
    def read_data(path, &block)
#      files = Array.new

      if File.directory?(path)
        Dir["#{path}/*"].each do |file|
#          files << File.expand_path(file, path)
          expanded = File.expand_path(file, path)
          File.open(expanded) do |fh|
            yield expanded, fh
          end
        end
      elsif File.exists?(path)
#        files << path
        File.open(path) do |fh|
          yield path, fh
        end
      else
        raise "Data file #{path} doesn't exist"
      end

#      return files
    end
  end
end

Dir["#{Antfarm.root}/lib/antfarm/plugins/*.rb"].each          { |file| require file }
Dir["#{Antfarm.root}/lib/antfarm/plugins/**/plugin.rb"].each  { |file| require file }
Dir["#{Antfarm::Helpers.user_plugins_dir}/*.rb"].each         { |file| require file }
Dir["#{Antfarm::Helpers.user_plugins_dir}/**/plugin.rb"].each { |file| require file }
