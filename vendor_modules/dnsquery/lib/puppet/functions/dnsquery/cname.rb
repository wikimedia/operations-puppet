# frozen_string_literal: true

# Retrieves a DNS CNAME record for a domain and returns it as a string.
Puppet::Functions.create_function(:'dnsquery::cname') do
  # @param domain the dns domain to lookup
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return An string representing the CNAME of a domain
  dispatch :dns_cname do
    param 'Stdlib::Fqdn', :domain
    optional_block_param :block
    return_type 'String'
  end

  def dns_cname(domain)
    Resolv::DNS.new.getresource(
      domain, Resolv::DNS::Resource::IN::CNAME
    ).name.to_s
  rescue Resolv::ResolvError
    block_given? ? yield : raise
  end
end
