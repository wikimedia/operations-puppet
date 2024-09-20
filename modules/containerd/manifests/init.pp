# SPDX-License-Identifier: Apache-2.0
#
# @summary
#   Install containerd
#
# @param ensure
#   Ensure containerd is installed and the service is running
class containerd (
  Wmflib::Ensure $ensure = present,
) {
  require containerd::configuration
  ensure_packages(['containerd'])

  service { 'containerd':
    ensure => stdlib::ensure($ensure, 'service'),
  }
}
