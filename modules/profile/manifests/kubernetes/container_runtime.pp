# SPDX-License-Identifier: Apache-2.0
# @summary
#   This profile is used to select the container runtime to install/configure
#
# @param container_runtime
#   Explicitly set the container runtime to use. If not set, the container runtime defaults to 'containerd'
#   Valid values: 'containerd', undef
class profile::kubernetes::container_runtime (
  Optional[String] $container_runtime = lookup('profile::kubernetes::container_runtime', { 'default_value' => undef }),
) {
    case $container_runtime {
      'containerd': {
        include profile::containerd
      }
      undef: {
        # Fall back to containerd if no container runtime is set explicitly
        if debian::codename::ge('bookworm') {
          include profile::containerd
        } else {
          # Bail out in case this is mistakenly applied to something older then bookworm
          # since older containerd versions are not supported.
          fail("Unsupported OS: ${facts['os']['release']['codename']}")
        }
      }
      default: {
        fail("Unsupported container runtime: ${container_runtime}")
      }
    }
}
