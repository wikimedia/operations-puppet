# SPDX-License-Identifier: Apache-2.0
# @summary this function is used to get a list of parameters passed to a resource, excluding the name parameter filtering out undeed paramters
#   This allows one to easily transform parameters into a json or yaml config file.  or pass them directly from
#   profile to a core class.
# @example
#   file { '/etc/foo/config.yaml':
#     ensure  => file,
#     mode    => $mode,
#     owner   => $owner,
#     content => wmflib::resource::filter_params('mode', 'owner'.to_yaml
#   }
Puppet::Functions.create_function(:'wmflib::resource::filter_params', Puppet::Functions::InternalFunction) do
  dispatch :filter_params do
    scope_param
    repeated_param 'Variant[String[1], Array[String[1]]]', :filter_keys
  end

  def filter_params(scope, *filter_keys)
    filter_keys.flatten!
    filter_keys << 'name'
    scope.resource.to_hash.collect{|k, v| [k.to_s, v]}.to_h.reject {|k, _v| filter_keys.include?(k) }
    # TODO: when ruby 2.5 everywhere
    # scope.resource.to_hash.transform_keys(&:to_s).reject {|k, _v| filter_keys.include?(k) }
  end
end
