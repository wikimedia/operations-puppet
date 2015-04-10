# == Function: merge_config(string|hash main_conf, string|hash service_conf)
#
# Merges the service-specific service_conf into main_conf. Both arguments
# can be either hashes or YAML-formatted strings. It returns the merged
# configuration hash.
#

def config_to_hash(conf)
  return YAML.load(conf) unless conf.is_a?(Hash)
  conf
end

module Puppet::Parser::Functions
  newfunction(:merge_config, :type => :rvalue, :arity => 2) do |args|
    main_conf, service_conf = *args.map { |arg|  config_to_hash(arg)}
    begin
      main_conf['services'][0]['conf'].update service_conf
    rescue
      fail('Badly formatted configuration.')
    end
	function_ordered_yaml([main_conf])
  end
end
