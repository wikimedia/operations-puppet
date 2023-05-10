# frozen_string_literal: true

require_relative '../../../puppet_x/voxpupuli/dnsquery/util'

# Do a DNS lookup and returns an array of addresses.
# This will follow CNAMEs and return any matching IPv4 or IPv6 addresses.
# See the more specific functions if you only want one type returned.
Puppet::Functions.create_function(:'dnsquery::lookup') do
  # @param domain the dns domain to lookup
  # @param force_ipv6 ensure we get AAAA answers even if the requestor has no global ipv6 address
  # @param config_info used to override the config for Resolve::DNS.new
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return An array of A and AAAA answers matching domain
  dispatch :dns_lookup do
    param 'Stdlib::Fqdn', :domain
    optional_param 'Boolean', :force_ipv6
    optional_param 'Optional[Dnsquery::Config_info]', :config_info
    optional_block_param :block
    return_type 'Array[Stdlib::IP::Address::Nosubnet]'
  end

  def dns_lookup(domain, force_ipv6 = false, config_info = nil)
    resolver = PuppetX::Voxpupuli::Dnsquery::Utils.resolver(config_info)
    ret = if force_ipv6
            call_function('dnsquery::a', domain, config_info) + call_function('dnsquery::aaaa', domain, config_info)
          else
            resolver.getaddresses(domain).map(&:to_s)
          end
    block_given? && ret.empty? ? yield : ret
  rescue Resolv::ResolvError
    block_given? ? yield : raise
  end
end
