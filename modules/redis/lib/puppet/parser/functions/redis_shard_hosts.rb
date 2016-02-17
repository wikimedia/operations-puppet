# == Function redis_shard_hosts( $my_ip, $shards)
#
# Return the list of hosts (cross-dc) that are part of the replication
# sets for this server
#
# Example:
#
# $shards = {
#   dc1 => {
#     s1 => { host => '192.168.0.1', port => 6379},
#     s2 => { host => '192.168.0.2', port => 6379},
#     s3 => { host => '192.168.0.1', port => 6380},
#   },
#   dc2 => {
#     s1 => { host => '192.168.1.1', port => 6379},
#     s2 => { host => '192.168.1.2', port => 6379},
#     s3 => { host => '192.168.1.3', port => 6379},
#   },
# }
# $my_ip = '192.168.0.1'
# # Returns the hostnames for 192.168.0.1, 192.168.1.1 and 192.168.1.3
# $r = redis_shard_hosts($my_ip, $shards)
#
module Puppet::Parser::Functions
  newfunction(:redis_shard_hosts, :type => :rvalue, :arity => 2) do |args|
    ip = args[0]
    shards = args[1]
    servers = {}
    my_shards = []
    # Read the data structure
    shards.each do |_, dc_shards|
      dc_shards.each do |name, data|
        if data['host'] == ip
          my_shards << name
        end
        servers[name] ||= []
        servers[name] << data['host']
      end
    end
    my_ips = []
    my_shards.each do |s|
      my_ips |= servers[s]
    end
    # Resolve the ip back to a hostname, used for ipsec
    my_ips.map { |h| function_ipresolve([h, 'ptr']) }
  end
end
