# SPDX-License-Identifier: Apache-2.0
# @summary
#   Configure containerd
#
# @param ensure
#   Ensure containerd configuration is present
#
# @param sandbox_image
#   The sandbox (Kubernetes pause) image to use
#
# @param dragonfly_enabled
#   Whether to configure containerd to use dragonfly dfdaemon as a registry mirror
#
# @param registry_auth
#  The auth string (base64 encoded username:password) to use for the registry
#
class containerd::configuration (
  Wmflib::Ensure $ensure = present,
  String $sandbox_image = 'docker-registry.discovery.wmnet/pause:3.6-1',
  Boolean $dragonfly_enabled = false,
  Optional[String] $registry_auth = undef,
) {
  file { '/etc/containerd':
    ensure => stdlib::ensure($ensure, 'directory'),
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/containerd/config.toml':
    ensure  => stdlib::ensure($ensure, 'file'),
    owner   => 'root',
    group   => 'root',
    mode    => '0440',
    content => template('containerd/containerd-config.toml.erb'),
    notify  => Service['containerd'],
  }
}
