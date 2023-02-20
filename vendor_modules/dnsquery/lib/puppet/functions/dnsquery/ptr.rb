# frozen_string_literal: true

# Retrieves DNS PTR records for a domain and returns them as an array.
Puppet::Functions.create_function(:'dnsquery::ptr') do
  # @param domain the dns domain to lookup
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return An array of PTR answeres matching domain
  dispatch :dns_ptr do
    param 'Stdlib::Fqdn', :domain
    optional_block_param :block
    return_type 'Array[Stdlib::Fqdn]'
  end

  def dns_ptr(domain)
    ret = Resolv::DNS.new.getresources(
      domain, Resolv::DNS::Resource::IN::PTR
    ).map do |res|
      res.name.to_s
    end
    block_given? && ret.empty? ? yield : ret
  rescue Resolv::ResolvError
    block_given? ? yield : raise
  end
end
