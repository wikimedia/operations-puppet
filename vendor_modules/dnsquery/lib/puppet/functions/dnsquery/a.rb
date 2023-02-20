# frozen_string_literal: true

# Retrieves DNS A records for a domain and returns them as an array.
Puppet::Functions.create_function(:'dnsquery::a') do
  # @param domain the dns domain to lookup
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return An array of A answers matching domain
  dispatch :dns_a do
    param 'Stdlib::Fqdn', :domain
    optional_block_param :block
    return_type 'Array[Stdlib::IP::Address::V4::Nosubnet]'
  end

  def dns_a(domain)
    ret = Resolv::DNS.new.getresources(
      domain, Resolv::DNS::Resource::IN::A
    ).map do |res|
      res.address.to_s
    end
    block_given? && ret.empty? ? yield : ret
  rescue Resolv::ResolvError
    block_given? ? yield : raise
  end
end
