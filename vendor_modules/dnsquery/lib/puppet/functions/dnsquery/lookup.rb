# frozen_string_literal: true

# Do a DNS lookup and returns an array of addresses.
# This will follow CNAMEs and return any matching IPv4 or IPv6 addresses.
# See the more specific functions if you only want one type returned.
Puppet::Functions.create_function(:'dnsquery::lookup') do
  # @param domain the dns domain to lookup
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return An array of A and AAAA answers matching domain
  dispatch :dns_lookup do
    param 'Stdlib::Fqdn', :domain
    optional_block_param :block
    return_type 'Array[Stdlib::IP::Address::Nosubnet]'
  end

  def dns_lookup(domain)
    ret = Resolv::DNS.new.getaddresses(domain).map(&:to_s)
    block_given? && ret.empty? ? yield : ret
  rescue Resolv::ResolvError
    block_given? ? yield : raise
  end
end
