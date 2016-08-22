# == Function: conftool( string $tags, string $selector, string $object_type='node')
#
# Fetch values from conftool. This should be used only for things that depend on the dynamic
# state from conftool but do not require the tight coordination.
#
# It will get (and json parse) values from conftool and return them, based on the specified
# selector.
#
# === Examples
#
# # get the current status of a node in confctl
# $status = conftool({ name => 'cp1052.eqiad.wmnet', service => 'varnish-fe'}) # returns a list of associated services
#
require 'json'

module Puppet::Parser::Functions
  newfunction(:conftool, :type => :rvalue, :arity => -2) do |args|
    case args.length
    when 2
      tags, type = *args
    when 1
      tags = args[0]
      type = 'node'
    end

    # Raise an error if tags is empty or not an hash
    if !tags.is_a?(Hash) || tags.empty?
      raise Puppet::ParseError, "tags should be in hash format"
    end

    # get the data and return them parsed as json
    begin
      selector = tags.map { |k, v| "#{k}=#{v}" }.join ","
      result = []
      data = function_generate(
        [
          '/usr/bin/confctl',
          '--object-type', type,
          'select', selector,
          'get'
        ]
      ).chomp

      # No result returns the empty list
      if data.empty?
        return []
      end

      data.split("\n").each do |line|
        entry = JSON.load(line)
        tags = entry.delete 'tags'
        obj_name = entry.keys.pop
        result.push({'name' => obj_name, 'tags' => tags, 'value' => entry[obj_name]})
      end
      result
    rescue
      raise Puppet::ParseError, "Unable to read data from conftool"
    end
  end
end
