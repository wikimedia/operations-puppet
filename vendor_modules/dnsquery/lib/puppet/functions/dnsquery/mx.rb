# frozen_string_literal: true

# Retrieves DNS MX records for a domain and returns them as an array.
Puppet::Functions.create_function(:'dnsquery::mx') do
  # @param domain the dns domain to lookup
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return An array of hashes representing the mx records for domain
  dispatch :dns_mx do
    param 'Stdlib::Fqdn', :domain
    optional_block_param :block
    return_type 'Array[Dnsquery::Mx]'
  end

  def dns_mx(domain)
    ret = Resolv::DNS.new.getresources(
      domain, Resolv::DNS::Resource::IN::MX
    ).map do |res|
      {
        'preference' => res.preference,
        'exchange' => res.exchange.to_s
      }
    end
    block_given? && ret.empty? ? yield : ret
  rescue Resolv::ResolvError
    block_given? ? yield : raise
  end
end
