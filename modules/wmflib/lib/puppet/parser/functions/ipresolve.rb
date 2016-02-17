# == Function: ipresolve( string $name_to_resolve, bool $ipv6 = false)
#
# Copyright (c) 2015 Wikimedia Foundation Inc.
#
# Performs a name resolution (for A AND AAAA records only) and returns
# an hash of arrays.
#
# Takes one or more names to resolve, and returns an array of all the
# A or AAAA records found. The resolution is actually only done when
# the ttl has expired. A particular nameserver can also be specified
# so only that is used, rather than the system default.
#
require 'resolv'

class DNSCacheEntry
  # Data structure for storing a DNS cached result.
  def initialize(entry, ttl)
    @value = entry
    @ttl = Time.now.to_i + ttl
  end

  def is_valid?(time)
    return @ttl > time
  end

  def value
    return @value.to_s
  end
end

class BasicTTLCache
  def initialize
    @cache = {}
  end

  def write(key, value, ttl)
    @cache[key] = DNSCacheEntry.new(value, ttl)
  end

  def delete(key)
    @cache.delete(key) if @cache.key?(key)
  end

  def is_valid?(key)
    # If the key exists, and its ttl has not expired, return true.
    # Return false (and maybe clean up the stale entry) otherwise.
    return false unless @cache.key?(key)
    t = Time.now.to_i
    return true if @cache[key].is_valid?t
    return false
  end

  def read(key)
    if is_valid?key
      return @cache[key].value
    end
    return nil
  end

  def read_stale(key)
    if @cache.key?(key)
      return @cache[key].value
    end
    return nil
  end
end

class DNSCached
  attr_accessor :dns
  def initialize(cache = nil, default_ttl = 300)
    @cache = cache || BasicTTLCache.new
    @default_ttl = default_ttl
  end

  def get_resource(name, type, nameserver)
    if nameserver.nil?
      dns = Resolv::DNS.open()
    else
      dns = Resolv::DNS.open(:nameserver => [nameserver])
    end
    cache_key = "#{name}_#{type}_#{nameserver}"
    res = @cache.read(cache_key)
    if (res.nil?)
      begin
        res = dns.getresource(name, type)
        # Ruby < 1.9 returns nil as the ttl...
        if res.ttl
          ttl = res.ttl
        else
          ttl = @default_ttl
        end
        if type == Resolv::DNS::Resource::IN::PTR
          retval = res.name
        else
          retval = res.address
        end
        @cache.write(cache_key, retval, ttl)
        retval.to_s
      rescue
      # If resolution fails and we do have a cached stale value, use it
        res = @cache.read_stale(cache_key)
        if res.nil?
          fail("DNS lookup failed for #{name} #{type}")
        end
        res.to_s
      end
    else
      res.to_s
    end
  end
end


module Puppet::Parser::Functions
  dns = DNSCached.new
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
