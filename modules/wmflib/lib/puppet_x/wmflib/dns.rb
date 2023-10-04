# SPDX-License-Identifier: Apache-2.0
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
require 'resolv'

module PuppetX
  module Wmflib
    module DNS
      class CacheEntry
        # Data structure for storing a DNS cached result.
        def initialize(entry, ttl)
          @value = entry
          @ttl = Time.now.to_i + ttl
        end

        def valid?(time)
          @ttl > time
        end

        def value
          @value.to_s
        end
      end

      class BasicTTLCache
        def initialize
          @cache = {}
        end

        def write(key, value, ttl)
          @cache[key] = CacheEntry.new(value, ttl)
        end

        def delete(key)
          @cache.delete(key) if @cache.key?(key)
        end

        def valid?(key)
          # If the key exists, and its ttl has not expired, return true.
          # Return false (and maybe clean up the stale entry) otherwise.
          return false unless @cache.key?(key)
          t = Time.now.to_i
          return true if @cache[key].valid?t

          false
        end

        def read(key)
          if valid?key
            return @cache[key].value
          end
          nil
        end

        def read_stale(key)
          if @cache.key?(key)
            return @cache[key].value
          end
          nil
        end
      end

      class Cached
        attr_accessor :dns
        def initialize(cache = nil, default_ttl = 300)
          @cache = cache || BasicTTLCache.new
          @default_ttl = default_ttl
        end

        def get_resource(name, type, nameserver)
          if nameserver.nil?
            dns = Resolv::DNS.open
          else
            dns = Resolv::DNS.open(:nameserver => [nameserver])
          end
          cache_key = "#{name}_#{type}_#{nameserver}"
          res = @cache.read(cache_key)
          if res.nil?
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
    end
  end
end
