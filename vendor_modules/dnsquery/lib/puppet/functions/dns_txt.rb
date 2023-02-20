# frozen_string_literal: true

# [DEPRECATED] Retrieves DNS TXT records for a domain and as an array.
Puppet::Functions.create_function(:dns_txt) do
  # @deprecated Please use the namespaced version dnsquery::txt
  # @param domain the dns question to lookup
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return The txt record for a domain as an array
  dispatch :dns_txt do
    param 'Stdlib::Fqdn', :domain
    optional_block_param :block
    return_type 'Array[Array[String]]'
  end

  def dns_txt(domain)
    Puppet.deprecation_warning('dns_txt', 'This method is deprecated please use the namespaced version dnsquery::txt')
    call_function('dnsquery::txt', domain)
  end
end
