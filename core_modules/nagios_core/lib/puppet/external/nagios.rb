#--------------------
# A script to retrieve hosts from ldap and create an importable
# cfservd file from them

require 'digest/md5'
# require 'ldap'
require File.dirname(__FILE__) + '/../external/nagios/parser.rb'
require File.dirname(__FILE__) + '/../external/nagios/base.rb'

# Top-level namespace for Nagios related things.
module Nagios
  NAGIOSVERSION = '1.1'.freeze
  # yay colors
  PINK = "\e[0;31m".freeze
  GREEN = "\e[0;32m".freeze
  YELLOW = "\e[0;33m".freeze
  SLATE = "\e[0;34m".freeze
  ORANGE = "\e[0;35m".freeze
  BLUE = "\e[0;36m".freeze
  NOCOLOR = "\e[0m".freeze
  RESET = "\e[0m".freeze

  def self.version
    NAGIOSVERSION
  end

  # Interface for reading in a Nagios config file.
  class Config
    def self.import(config)
      text = ''

      File.open(config) do |file|
        file.each do |line|
          text += line
        end
      end
      parser = Nagios::Parser.new
      parser.parse(text)
    end

    def self.each
      Nagios::Object.objects.each do |object|
        yield object
      end
    end
  end
end
