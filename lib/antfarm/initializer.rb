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

module Antfarm
  class << self
    attr_accessor :config

    def env
      return nil if @config.nil?
      return @config.environment
    end
  end

  class Initializer
    attr_reader :configuration

    # Run the initializer, first making the configuration object available
    # to the user, then creating a new initializer object, then running the
    # given command.
    def self.run(command = :process, configuration = Configuration.new)
      yield configuration if block_given?
      initializer = new configuration
      initializer.send(command)
    end

    def initialize(configuration)
      @configuration = configuration
    end

    def process
      update_configuration

      Antfarm.config = @configuration

      initialize_database
      initialize_logger
      initialize_outputter
    end

    def init
      # Load the Antfarm requirements
      load_requirements

      # Make sure an application directory exists for the current user
      Antfarm::Helpers.create_user_directory
    end

    #######
    private
    #######

    def load_requirements
      require 'active_record'
      require 'logger'
      require 'yaml'

      require 'antfarm/errors'
      require 'antfarm/helpers'
      require 'antfarm/ip_addr_ext'
      require 'antfarm/models'
      require 'antfarm/plugin'
      require 'antfarm/version'
    end

    def update_configuration
      begin
        config = YAML.load(IO.read(Antfarm::Helpers.config_file))
      rescue Errno::ENOENT # no such file...
        config = Hash.new
      end

      # If they weren't set in the configuration object when yielded,
      # then set them to the defaults specified in the user's config file.
      # If they don't exist in the config file, set them to the defaults
      # specified in the configuration object.
      if @configuration.environment.nil?
        if config['environment']
          @configuration.environment = config['environment']
        else
          @configuration.default_environment
        end
      end

      if @configuration.log_level.nil?
        if config['log_level']
          @configuration.log_level = config['log_level']
        else
          @configuration.default_log_level
        end
      end
    end

    # Currently, SQLite3 and PostgreSQL databases are the only ones supported.
    # The name of the ANTFARM environment (which defaults to 'antfarm') is the
    # name used for the database file and the log file.
    def initialize_database
      begin
        config = YAML.load(IO.read(Antfarm::Helpers.config_file))
      rescue Errno::ENOENT # no such file...
        config = Hash.new
      end

      # Database setup based on adapter specified
      if config && config[@configuration.environment] and config[@configuration.environment].has_key?('adapter')
        if config[@configuration.environment]['adapter'] == 'sqlite3'
          config[@configuration.environment]['database'] = Antfarm::Helpers.db_file
        elsif config[@configuration.environment]['adapter'] == 'postgres'
          config[@configuration.environment]['database'] = @configuration.environment
        else
          # If adapter specified isn't one of sqlite3 or postgresql,
          # default to SQLite3 database configuration.
          config = nil
        end
      else
        # If the current environment configuration doesn't specify a
        # database adapter, default to SQLite3 database configuration.
        config = nil
      end

      # Default to SQLite3 database configuration
      config ||= { @configuration.environment => { 'adapter' => 'sqlite3', 'database' => Antfarm::Helpers.db_file } }

      ActiveRecord::Base.establish_connection(config[@configuration.environment])
    end

    def initialize_logger
      logger       = ::Logger.new(Antfarm::Helpers.log_file)
      logger.level = ::Logger.const_get(@configuration.log_level.upcase)

      ActiveRecord::Base.logger = logger
      Antfarm.logger_callback = lambda do |severity,msg|
        logger.send(severity,msg)
      end
    end

    def initialize_outputter
      Antfarm.outputter_callback = @configuration.outputter
    end
  end

  class Configuration
    attr_accessor :environment
    attr_accessor :log_level
    attr_accessor :outputter
    
    def initialize
      @environment = nil
      @log_level   = nil
      @outputter   = nil
    end

    def default_environment
      @environment = 'antfarm'
    end

    def default_log_level
      @log_level = 'warn'
    end
  end
end
