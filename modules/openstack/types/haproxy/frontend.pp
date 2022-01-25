type OpenStack::HAProxy::Frontend = Struct[{
  port                 => Stdlib::Port,
  acme_chief_cert_name => Optional[String],
}]
