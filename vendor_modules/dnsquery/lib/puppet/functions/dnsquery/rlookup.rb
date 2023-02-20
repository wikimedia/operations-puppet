# frozen_string_literal: true

# Retrieves results from DNS reverse lookup and returns it as an array.
Puppet::Functions.create_function(:'dnsquery::rlookup') do
  # @param address the ip address to lookup
  # @param block an optional lambda to return a default value in case the lookup fails
  # @return An array of hostnames matching the ip address
  dispatch :dns_rlookup do
    param 'Stdlib::IP::Address::Nosubnet', :address
    optional_block_param :block
    return_type 'Array[Stdlib::Fqdn]'
  end

  def dns_rlookup(address)
    addr = IPAddr.new(address)
    ret = Resolv::DNS.new.getresources(
      addr.reverse, Resolv::DNS::Resource::IN::PTR
    ).map do |res|
      res.name.to_s
    end
    block_given? && ret.empty? ? yield : ret
  rescue Resolv::ResolvError
    block_given? ? yield : raise
  end
end
