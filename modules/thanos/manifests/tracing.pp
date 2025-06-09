# SPDX-License-Identifier: Apache-2.0
# == Define: thanos::tracing
#
# A wrapper define to get type safety around Thanos tracing configuration.
#
# = Parameters
# [*service_name*] The service name to attach to traces
# [*sampler_type*] See Thanos::Tracing::Sampler type
# [*sampler_param*] The sampler parameter, if needed
# [*file_path*] The path to resulting file, defaults to title

define thanos::tracing (
  String $service_name,
  Thanos::Tracing::Sampler $sampler_type,
  Wmflib::Ensure $ensure = present,
  Optional[String] $sampler_param = undef,
  Stdlib::Unixpath $file_path = $title,
) {
    file { $file_path:
        ensure  => present,
        content => template('thanos/tracing-config.yaml.erb'),
    }
}
