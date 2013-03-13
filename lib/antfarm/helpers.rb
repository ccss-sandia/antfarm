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

require 'fileutils'

module Antfarm
  # Symbolic marker points on the fuzzy logic certainty factor scale.
  # Certainty Factors (CF)
  CF_PROVEN_TRUE   =  1.0000
  CF_LIKELY_TRUE   =  0.5000
  CF_LACK_OF_PROOF =  0.0000
  CF_LIKELY_FALSE  = -0.5000
  CF_PROVEN_FALSE  = -1.0000

  # Amount by which a value can differ and still be considered the same.
  # Mainly used as a buffer against floating point round-off errors.
  CF_VARIANCE      =  0.0001

  @user_dir        = nil
  @outputter       = nil
  @logger_callback = nil

  class << self
    attr_accessor :logger_callback
    attr_accessor :outputter
    attr_accessor :user_dir
  end

  def self.clamp(x, low = CF_PROVEN_FALSE, high = CF_PROVEN_TRUE)
    if x < low
      return low
    elsif x > high
      return high
    else
      return x
    end
  end

  def self.output(message)
    @outputter.puts(message) unless @outputter.nil?
  end

  def self.log(level, *msg)
    @logger_callback.call(level, msg.join) if @logger_callback
  end

  def self.simplify_interfaces
    #TODO
  end

  def self.timestamp
    return Time.now.utc.xmlschema
  end

  module Helpers
    def self.db_dir
      return File.expand_path("#{self.user_dir}/db")
    end

    def self.db_file
      return File.expand_path("#{self.user_dir}/db/#{Antfarm.env}.db")
    end

    def self.log_dir
      return File.expand_path("#{self.user_dir}/log")
    end

    def self.log_file
      return File.expand_path("#{self.user_dir}/log/#{Antfarm.env}.log")
    end

    def self.config_file
      return File.expand_path("#{self.user_dir}/config.yml")
    end

    def self.history_file
      return File.expand_path("#{self.user_dir}/history")
    end

    def self.user_plugins_dir
      return File.expand_path("#{self.user_dir}/plugins")
    end

    #######
    private
    #######

    USER_DIRECTORIES = ['db', 'log', 'plugins']

    def self.user_dir
      return @user_dir unless @user_dir.nil?
      return self.create_user_directory
    end

    # Initializes a suitable directory structure for the user
    def self.create_user_directory
      USER_DIRECTORIES.each do |directory|
        path = "#{ENV['HOME']}/.antfarm/#{directory}"
        # Just to be safe... don't want to wipe out existing user data!
        unless File.exists?(path)
          FileUtils.makedirs(path)
          Antfarm.log :info, "User '#{directory}' directory created in #{ENV['HOME'] + '/.antfarm'}"
        end
      end

      config_file = "#{ENV['HOME']}/.antfarm/config.yml"
      # Just to be safe... don't want to wipe out existing user data!
      unless File.exists?(config_file)
        File.open(config_file, 'w') do |file|
          file.puts '---'
          file.puts 'environment: antfarm'
          file.puts 'log_level: warn'
        end
        Antfarm.log :info, "Default config file created at #{ENV['HOME'] + '/.antfarm/config.yml'}"
      end

      return @user_dir = (ENV['HOME'] + '/.antfarm')
    end
  end
end
