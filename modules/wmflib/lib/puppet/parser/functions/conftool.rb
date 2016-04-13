# == Function: conftool( string $tags, string $selector, string $object_type='node')
#
# Fetch values from conftool. This should be used only for things that depend on the dynamic
# state from conftool but do not require the tight coordination.
#
# It will get (and json parse) values from conftool and return them, based on the specified
# tags and selector (which can be either an specific object name or 'all').
#
# === Examples
#
# # get the current status of a node in confctl
# $status = conftool "dc=${::site},cluster=${cluster},service=apache2", $::fqdn
# => {pooled => "inactive", weight => 10}
#
require 'json'

module Puppet::Parser::Functions
  newfunction(:conftool, :type => :rvalue, :arity => -2) do |args|
    case arg.length
    when 3
      tags, selector, type = args
    when 2
      tags, selector = args
      type = 'node'
    else
      raise Puppet::ParseError, "Wrong number of arguments for conftool()"
    end

    # get the data and return them parsed as json
    begin
      data = function_generate(
        [
          '/usr/bin/conftool',
          '--object-type', type,
          '--tags', tags,
          '--action', 'get', selector
        ]
      )
      result = JSON.load(data)
      if selector == 'all'
        result[selector]
      else
        result
      end
    rescue
      raise Puppet::ParseError, "Unable to read data from conftool"
    end
  end
end
