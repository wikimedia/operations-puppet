# @summary type used for DNS SOA records
type Dnsquery::Soa = Struct[{
  mname   => Stdlib::Fqdn,
  rname   => Stdlib::Fqdn,
  expire  => Integer,
  minimum => Integer,
  refresh => Integer,
  retry   => Integer,
  serial  => Integer,
}]
