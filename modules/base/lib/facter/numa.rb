# numa.rb - NUMA cpu+network topology info for puppet facter
#
# Copyright 2017 Brandon Black
# Copyright 2017 Wikimedia Foundation, Inc.
#
# Network interfaces are not always reported by the kernel as attached to a
# specific NUMA node for a variety of reasons: virtual/software interfaces,
# certain single-node hardware configurations, and some multi-node
# configurations which use a shared I/O hub to access the network device.
#
# For ease-of-use reasons, any network interface the kernel doesn't indicate as
# attached to a single specific node is assigned to all nodes in the output
# here, as shown for "lo" in the first example below.
#
# All (two!) known uses of this data only consume the "device_to_htset" data so
# far, so I've limited the fact data output to only that data for now to avoid
# fact bloat.  We can expose other related data later if there's a need for it.
# The examples below show all of the other possible intermediate data outputs,
# for reference.
#
# Example with 2x numa nodes as 2x cpu dies.  Each die has 4 physical (8 logical
# HT) cpu cores, system would show "16 cpus" in the simple view.  eth0 and eth1
# are each attached to a distinct node:
#
# numa = {
#    "node_to_htset" => { # not currently exported!
#        0 => [[0, 8], [2, 10], [4, 12], [6, 14]],
#        1 => [[1, 9], [3, 11], [5, 13], [7, 15]],
#    },
#    "device_to_htset" => {
#        "eth0" => [[0, 8], [2, 10], [4, 12], [6, 14]],
#        "eth1" => [[1, 9], [3, 11], [5, 13], [7, 15]],
#        "lo"   => [[0, 8], [1, 9], [2, 10], [3, 11],
#                   [4, 12], [5, 13], [6, 14], [7, 15]],
#    }
# }
#
# Minimal example, how things might look on a small or virtual node with 1
# single-core CPU lacking HT:
#
# numa = {
#    "node_to_htset" => { # not currently exported!
#        0 => [[0]]
#    }
#    "device_to_htset" => {
#        "eth0" => [[0]],
#        "lo"   => [[0]],
#    }
# }
#

require 'facter'
require 'pathname'

# fragments of long sysfs glob pathname, to keep line len down later
tsl_frag1 = '/sys/devices/system/node'
tsl_frag2 = 'cpu[0-9]*/topology/thread_siblings_list'

Facter.add('numa') do
  setcode do
    node_to_htset = {}
    device_to_htset = {}
    nodes = Pathname.glob('/sys/devices/system/node/node[0-9]*')
                    .map { |n| /([0-9]+)$/.match(n.to_s)[0].to_i }.sort
    nodes.each do |n|
      node_to_htset[n] =
        Pathname.glob("#{tsl_frag1}/node#{n}/#{tsl_frag2}")
                .map do |c|
                  File.open(c).read.split(',').map(&:to_i).sort
                end.sort.uniq
    end
    Pathname.glob('/sys/class/net/*').sort.each do |d|
      dev = d.to_s.split('/')[4]
      nodefile = "#{d}/device/numa_node"
      raw_node = File.exist?(nodefile) ? File.open(nodefile, 'r').read.to_i : -1
      dev_nodes = raw_node >= 0 ? [raw_node] : nodes
      device_to_htset[dev] = []
      dev_nodes.each do |dn|
        device_to_htset[dev].concat(node_to_htset[dn])
      end
      device_to_htset[dev].sort!
    end
    { 'device_to_htset' => device_to_htset }
  end
end
