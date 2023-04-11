# == Function: ipresolve(string $name_to_resolve, string $type = '4', string $nameserver = nil)
#
# Copyright (c) 2015-2017 Wikimedia Foundation Inc.
#
# Performs a name resolution (for A, AAAA and PTR records only) and returns a
# string.
#
# Takes one name to resolve, and returns a string of the A, AAAA or PTR record
# found. The resolution is actually only done when the ttl has expired. A
# particular nameserver can also be specified so only that is used, rather than
# the system default.
#
require_relative '../../../puppet_x/wmflib/dns.rb'

module Puppet::Parser::Functions
  dns = PuppetX::Wmflib::DNS::Cached.new
  newfunction(:ipresolve, :type => :rvalue, :arity => -1) do |args|
    name = args[0]
    if args[1].nil?
      type = 4
    elsif args[1].to_s.downcase == 'ptr'
      type = 'ptr'
    else
      type = args[1].to_i
    end
    nameserver = args[2] # Ruby returns nil if there's nothing there
    if type == 4
      source = Resolv::DNS::Resource::IN::A
    elsif type == 6
      source = Resolv::DNS::Resource::IN::AAAA
    elsif type == 'ptr'
      source = Resolv::DNS::Resource::IN::PTR
      # Transform the provided IP address in a PTR record
      case name
      when Resolv::IPv4::Regex
        ptr = Resolv::IPv4.create(name).to_name
      when Resolv::IPv6::Regex
        ptr = Resolv::IPv6.create(name).to_name
      else
        fail("Cannot interpret #{name} as an address")
      end
      name = ptr
    else
      raise ArgumentError, 'Type must be 4, 6 or ptr'
    end
    return dns.get_resource(name, source, nameserver).to_s
  end
end
