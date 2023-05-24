# SPDX-License-Identifier: Apache-2.0
require 'facter'

# Returns true if a puppet is executing as part of a container build.
Facter.add('wmflib::container_build') do
  confine :kernel => 'Linux'
  setcode do
    # If pid 1 is systemd then we must not be building a container, otherwise
    # we assume we are building a container. Alternatively we could check for
    # the container env var, which does not seem to exist when building.
    case File.read('/proc/1/comm').chomp
    when 'systemd'
      false
    else
      true
    end
  end
end
