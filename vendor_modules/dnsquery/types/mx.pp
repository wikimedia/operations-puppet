# @summary type used for DNS MX records
type Dnsquery::Mx = Struct[{
  preference => Integer[0,65535],
  exchange   => Stdlib::Fqdn,
}]
