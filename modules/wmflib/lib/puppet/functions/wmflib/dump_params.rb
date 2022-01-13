# @summary this function is used to get a list of parameters passed to a class.  This allows one to easily
#   transform class parameters into a json/yaml config file
# @example
#   file { '/etc/foo/config.yaml':
#     ensure => file,
#     content => extlib::dump_params.to_yaml
#   }
Puppet::Functions.create_function(:'wmflib::dump_params', Puppet::Functions::InternalFunction) do
  # @param filter_keys an optional parameters of keys to filter out
  dispatch :dump_params do
    scope_param
    optional_param 'Array[String[1]]', :filter_keys
  end

  def dump_params(scope, filter_keys = ['name'])
    scope.resource.to_hash.transform_keys(&:to_s).reject {|k, _v| filter_keys.include?(k) }
  end
end
