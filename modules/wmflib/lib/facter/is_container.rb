# SPDX-License-Identifier: Apache-2.0
require 'facter'

# Returns true if puppet is being run inside a container
Facter.add('wmflib::is_container') do
  confine :kernel => 'Linux'
  setcode do
    case Facter.value('virtual')
    when 'crio', 'podman', 'docker', 'lxc', 'systemd_nspawn', 'container_other'
      true
    else
      false
    end
  end
end
