# SPDX-License-Identifier: Apache-2.0
# @summary
#   This profile is used to select the container runtime to install/configure
#
# @param container_runtime
#   Explicitly set the container runtime to use. If not set, the container runtime is decided based on the OS version.
#   If the OS version is Debian Bookworm or newer, containerd is used. Otherwise, docker is used.
#   Valid values: 'docker', 'containerd', undef
class profile::kubernetes::container_runtime (
  Optional[String] $container_runtime = lookup('profile::kubernetes::container_runtime', { 'default_value' => undef }),
) {
    case $container_runtime {
      'containerd': {
        include profile::containerd
      }
      'docker': {
        include profile::docker::engine
      }
      undef: {
        # If no container runtime is set explicitely, decide based on the OS version
        if debian::codename::ge('bookworm') {
          include profile::containerd
        } else {
          include profile::docker::engine
        }
      }
      default: {
        fail("Unsupported container runtime: ${container_runtime}")
      }
    }
}
