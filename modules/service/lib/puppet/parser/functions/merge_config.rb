# == Function: merge_config(string|hash main_conf, string|hash service_conf)
#
# Merges the service-specific service_conf into main_conf. Both arguments
# can be either hashes or YAML-formatted strings. It returns the merged
# configuration hash.
#

module Puppet::Parser::Functions
  newfunction(:merge_config, :type => :rvalue, :arity => 2) do |args|
    main_conf, service_conf = *args.map do |arg|
      arg.is_a?(Hash) ? arg : YAML.load(arg)
    end
    begin
      main_conf['services'][0]['conf'].update service_conf
    rescue
      fail('Badly formatted configuration.')
    end
    call_function('to_yaml', [main_conf])
  end
end
