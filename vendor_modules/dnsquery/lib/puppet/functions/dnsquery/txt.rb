# frozen_string_literal: true

# Retrieves DNS TXT records for a domain and return as an array.
Puppet::Functions.create_function(:'dnsquery::txt') do
  # @param domain the dns question to lookup
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return The txt domain for a domain
  dispatch :dns_txt do
    param 'Stdlib::Fqdn', :domain
    optional_block_param :block
    return_type 'Array[Array[String]]'
  end

  def dns_txt(domain)
    ret = Resolv::DNS.new.getresources(
      domain, Resolv::DNS::Resource::IN::TXT
    ).map(&:strings)
    # TODO: we should really do .map(&:join) above but it would be a breaking change
    block_given? && ret.empty? ? yield : ret
  rescue Resolv::ResolvError
    block_given? ? yield : raise
  end
end
