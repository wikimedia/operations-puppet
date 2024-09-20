# SPDX-License-Identifier: Apache-2.0
#
# @summary
#   Install nerdctl
#
# @param ensure
#   Ensure nerdctl is installed
#
# @param namespace
#   containerd namespace nerdctl should use by default.
#   Default is 'k8s.io', which is the namespace Kubernetes uses by default.
class containerd::nerdctl (
  Wmflib::Ensure $ensure = present,
  String $namespace = 'k8s.io',
) {
  ensure_packages(['nerdctl'])

  file { '/etc/nerdctl':
    ensure => stdlib::ensure($ensure, 'directory'),
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/nerdctl/nerdctl.toml':
    ensure  => stdlib::ensure($ensure, 'file'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('containerd/nerdctl.toml.erb'),
  }
}
