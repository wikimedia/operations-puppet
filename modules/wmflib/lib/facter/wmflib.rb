# SPDX-License-Identifier: Apache-2.0
require 'facter'

Facter.add(:wmflib, :type => :aggregate) do
  confine :kernel => 'Linux'

  chunk(:is_container) do
    case Facter.value('virtual')
    when 'crio', 'podman', 'docker', 'lxc',
         'systemd_nspawn', 'container_other'
      true
    else
      false
    end
  end

  chunk(:container_build) do
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

  aggregate do |chunks|
    chunks.reduce({}) do |memo, (k, v)|
      memo[k.to_s] = v
      memo
    end
  end
end
