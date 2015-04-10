# == Function: merge_config(string|hash main_conf, string|hash service_conf)
#
# Merges the service-specific service_conf into main_conf. Both arguments
# can be either hashes or YAML-formatted strings. It returns the merged
# configuration hash.
#
module Puppet::Parser::Functions
  newfunction(:merge_config, type: :rvalue, arity: 2) do |args|
    main_conf, service_conf = *args
    main_conf = YAML.load(main_conf) unless Hash === main_conf
    service_conf = YAML.load(service_conf) unless Hash === service_conf
    main_conf['services'][0]['conf'].update service_conf
		main_conf
  end
end

