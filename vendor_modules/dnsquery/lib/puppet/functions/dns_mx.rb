# frozen_string_literal: true

# [DEPRECATED] Retrieves DNS MX records for a domain and returns them as an array.
Puppet::Functions.create_function(:dns_mx) do
  # @deprecated Please use the namespaced version dnsquery::mx
  # @param domain the dns domain to lookup
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return An array of hashes representing the mx records for domain
  dispatch :dns_mx do
    param 'Stdlib::Fqdn', :domain
    optional_block_param :block
    return_type 'Array[Dnsquery::Mx]'
  end

  def dns_mx(domain, &block)
    Puppet.deprecation_warning('dns_mx', 'This method is deprecated please use the namespaced version dnsquery::mx')
    call_function('dnsquery::mx', domain, &block)
  end
end
