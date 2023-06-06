# SPDX-License-Identifier: Apache-2.0
# @summary this function is used to get a list of parameters passed to a resource, excluding the name parameter.
#   This allows one to easily transform parameters into a json or yaml config file.  or pass them directly from
#   profile to a core class.
# @example
#   file { '/etc/foo/config.yaml':
#     ensure => file,
#     content => wmflib::resource::dump_params.to_yaml
#   }
Puppet::Functions.create_function(:'wmflib::resource::dump_params', Puppet::Functions::InternalFunction) do
  dispatch :dump_params do
    scope_param
  end

  def dump_params(scope)
    params = scope.resource.to_hash.collect{|k, v| [k.to_s, v]}.to_h
    params.delete('name')
    params
    # TODO: when ruby 2.5 everywhere
    # scope.resource.to_hash.transform_keys(&:to_s)
  end
end
