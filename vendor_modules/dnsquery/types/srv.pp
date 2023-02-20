# @summary type used for DNS SRV records
type Dnsquery::Srv = Struct[{
  priority => Integer[0,65535],
  weight   => Integer[0,65535],
  port     => Stdlib::Port,
  target   => Stdlib::Fqdn,
}]
