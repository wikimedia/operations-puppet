# SPDX-License-Identifier: Apache-2.0
Facter.add('ganeti_cluster') do
  confine :kernel => :linux
  confine do
    File.exists?('/var/lib/ganeti/ssconf_cluster_name')
  end

  setcode do
    File.read('/var/lib/ganeti/ssconf_cluster_name').chomp
  end
end

Facter.add('ganeti_master') do
  confine :kernel => :linux
  confine do
    File.exists?('/var/lib/ganeti/ssconf_master_node')
  end

  setcode do
    File.read('/var/lib/ganeti/ssconf_master_node').chomp
  end
end
