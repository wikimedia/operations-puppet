# frozen_string_literal: true

# [DEPRECATED] Retrieves a DNS CNAME record for a domain and returns it as a string.
Puppet::Functions.create_function(:dns_cname) do
  # @deprecated Please use the namespaced version dnsquery::cname
  # @param domain the dns domain to lookup
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return An string representing the CNAME of a domain
  dispatch :dns_cname do
    param 'Stdlib::Fqdn', :domain
    optional_block_param :block
    return_type 'Stdlib::Fqdn'
  end

  def dns_cname(domain, &block)
    Puppet.deprecation_warning('dns_cname', 'This method is deprecated please use the namespaced version dnsquery::cname')
    call_function('dnsquery::cname', domain, &block)
  end
end
