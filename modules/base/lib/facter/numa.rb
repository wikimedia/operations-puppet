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
# Example with 2x numa nodes as 2x cpu dies.  Each die has 4 physical (8 logical
# HT) cpu cores, system would show "16 cpus" in the simple view.  eth0 and eth1
# are each attached to a distinct node:
#
# numa = {
#    "nodes" => [0,1]
#    "device_to_node" => {
#        "eth0" => [0]
#        "eth1" => [1]
#        "lo"   => [0,1]
#    }
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
#    "nodes" => [0]
#    "device_to_node" => {
#        "eth0" => [0],
#        "lo"   => [0],
#    }
#    "device_to_htset" => {
#        "eth0" => [[0]],
#        "lo"   => [[0]],
#    }
# }
#

require 'facter'
require 'pathname'

def nodes_list
  Pathname.glob('/sys/devices/system/node/node[0-9]*')
          .map { |n| /([0-9]+)$/.match(n.to_s)[0].to_i }.sort
end

def nodes_to_htsets(nodes)
  tsl_glob = 'cpu[0-9]*/topology/thread_siblings_list'
  node_to_htset = {}
  nodes.each do |n|
    node_to_htset[n] =
      Pathname.glob("/sys/devices/system/node/node#{n}/#{tsl_glob}")
              .map do |c|
                File.open(c).read.split(',').map(&:to_i).sort
              end.sort.uniq
  end
  node_to_htset
end

Facter.add('numa') do
  setcode do
    nodes = nodes_list
    node_to_htset = nodes_to_htsets(nodes)
    device_to_node = {}
    device_to_htset = {}
    Pathname.glob('/sys/class/net/*').sort.each do |d|
      dev = d.to_s.split('/')[4]
      nodefile = "#{d}/device/numa_node"
      raw_node = File.exist?(nodefile) ? File.open(nodefile, 'r').read.to_i : -1
      if raw_node >= 0 && nodes.length > 1
        device_to_node[dev] = [raw_node]
        device_to_htset[dev] = node_to_htset[raw_node]
      else
        device_to_node[dev] = nodes
        device_to_htset[dev] = node_to_htset.values.flatten(1).sort
      end
    end
    {
      'nodes' => nodes,
      'device_to_node' => device_to_node,
      'device_to_htset' => device_to_htset,
    }
  end
end
