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
# Most software (as of this writing) will probably only consume the
# "device_to_htset" output at the end, but the intermediate data is exported as
# well in case it makes other use-cases easier in the future.
#
# Example with 2x numa nodes as 2x cpu dies.  Each die has 4 physical (8
# logical HT) cpu cores.  eth0 and eth1 are each attached to a distinct node:
#
# numa = {
#    "node_count" => 2,
#    "node_to_cpu" => {
#        0 => [0, 2, 4, 6, 8, 10, 12, 14],
#        1 => [1, 3, 5, 7, 9, 11, 13, 15],
#    },
#    "node_to_htset" => {
#        0 => [[0, 8], [2, 10], [4, 12], [6, 14]],
#        1 => [[1, 9], [3, 11], [5, 13], [7, 15]],
#    },
#    "node_to_device" => {
#        0 => ["eth0", "lo"],
#        1 => ["eth1", "lo"],
#    },
#    "device_to_node" => {
#        "eth0" => [0],
#        "eth1" => [1],
#        "lo"   => [0,1],
#    },
#    "device_to_cpu" => {
#        "eth0" => [0, 2, 4, 6, 8, 10, 12, 14],
#        "eth1" => [1, 3, 5, 7, 9, 11, 13, 15],
#        "lo"   => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
#    }
#    "device_to_htset" => {
#        "eth0" => [[0, 8], [2, 10], [4, 12], [6, 14]],
#        "eth1" => [[1, 9], [3, 11], [5, 13], [7, 15]],
#        "lo"   => [[0, 8], [1, 9], [2, 10], [3, 11], [4, 12], [5, 13], [6, 14], [7, 15]],
#    }
# }
#
# Minimal example, how things might look on a small or virtual node with 1
# single-core CPU lacking HT:
#
# numa = {
#    "node_count" => 1,
#    "node_to_cpu" => {
#        0 => [0]
#    }
#    "node_to_htset" => {
#        0 => [[0]]
#    }
#    "node_to_device" => {
#        0 => ["eth0", "lo"]
#    }
#    "device_to_node" => {
#        "eth0" => [0],
#        "lo"   => [0],
#    }
#    "device_to_cpu" => {
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

Facter.add('numa') do
  setcode do
    output = {}
    output['node_to_cpu'] = {}
    output['node_to_htset'] = {}
    output['node_to_device'] = {}
    output['device_to_node'] = {}
    output['device_to_cpu'] = {}
    output['device_to_htset'] = {}
    nodes = Pathname.glob('/sys/devices/system/node/node[0-9]*')
                    .map { |n| /([0-9]+)$/.match(n.to_s)[0].to_i }.sort
    output['node_count'] = nodes.length
    nodes.each do |n|
      node_cpus_glob = "/sys/devices/system/node/node#{n}/cpu[0-9]*"
      output['node_to_device'][n] = []
      output['node_to_cpu'][n] =
        Pathname.glob(node_cpus_glob).map do |c|
          /([0-9]+)$/.match(c.to_s)[0].to_i
        end.sort
      output['node_to_htset'][n] =
        Pathname.glob(node_cpus_glob + '/topology/thread_siblings_list')
                .map do |c|
                  File.open(c).read.strip.split(',').map(&:to_i).sort
                end.sort.uniq
    end
    Pathname.glob('/sys/class/net/*').sort.each do |d|
      dev = d.to_s.split('/')[4]
      nodefile = "#{d}/device/numa_node"
      raw_node = -1
      raw_node = File.open(nodefile, 'r').read.to_i if File.exist?(nodefile)
      dev_nodes = raw_node >= 0 ? [raw_node] : nodes
      output['device_to_node'][dev] = dev_nodes
      dev_nodes.each do |dev_node|
        output['node_to_device'][dev_node].push(dev)
      end
      output['device_to_cpu'][dev] = dev_nodes.map do |dn|
        output['node_to_cpu'][dn]
      end.flatten.sort
      output['device_to_htset'][dev] = []
      dev_nodes.each do |dn|
        output['device_to_htset'][dev].concat(output['node_to_htset'][dn])
      end
      output['device_to_htset'][dev].sort!
    end
    output
  end
end
