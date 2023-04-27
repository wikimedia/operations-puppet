# @summary Type to validate the config_info passed to Resolve::DNS.new
type Dnsquery::Config_info = Struct[{
  'nameserver'       => Variant[Stdlib::IP::Address::Nosubnet, Array[Stdlib::IP::Address::Nosubnet]],
  Optional['search'] => Array[Stdlib::Fqdn],
  Optional['ndots']  => Integer[1,63],
}]
