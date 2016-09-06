# == Function: map_resources( string resource, array $titles, hash $params)
#
# This is supposed to be used temporarily before we can switch to
# the future parser and use a proper map function.
#
# This takes 3 arguments:
#   - the resource to map to
#   - A list (or a single string) of resource titles
#   - A set of parameters in the form of an hash.
# If Some variable in the hash needs to be interpolated with the resource title,
# then use @@title@@ in it.
#
# === Examples
#
# $instances = [6379, 6380]
# $parameters = { settings => {maxmemory => '100mb', port => '@@title@@', appendfilename => 'redis-@@title@@.aof' }}
# map_resources(redis::instance, $instances, $parameters)
require 'puppet/parser/functions'
def deep_replace(data, replacement)
  if data.is_a?(Hash)
    data.each { |k, v| data[k] = deep_replace(v, replacement) }
    puts data
  elsif data.is_a?(Array)
    data = data.map{ |v| deep_replace(v, replacement) }
  else
    data = data.gsub(/\@\@title\@\@/, replacement)
  end
  data
end


module Puppet::Parser::Functions
  newfunction(:map_resources, :arity => 3) do |args|
    type, titles, params = args
    titles = [titles] unless titles.is_a?(Array)
    titles.each do |title|
      parameters = params.clone
      deep_replace(parameters, title)
      Puppet::Parser::Functions.function(:defined_with_params)
      if function_defined_with_params(["#{type}[#{title}]", parameters])
        Puppet.debug("Resource #{type}[#{title}] not created b/c it already exists")
      else
        function_create_resources([type.capitalize, { title => parameters }])
      end
    end
  end
end
