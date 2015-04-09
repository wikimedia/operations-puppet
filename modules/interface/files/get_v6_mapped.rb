#!/usr/bin/ruby

require 'ipaddr';

if ARGV.length != 2
    raise "Requires two arguments: interface and host address (lower 64 bits)"
end

intf = ARGV[0];
host = ARGV[1];

rd_cmd = "/bin/rdisc6 -1nq #{intf}";
network = `#{rd_cmd}`;
if $?.exitstatus != 0
    raise "Command '#{rd_cmd}' failed"
end

print (IPAddr.new(network) | IPAddr.new(host)).to_s() + "\n"
