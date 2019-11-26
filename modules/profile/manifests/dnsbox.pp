# Combo profile for configuring production dnsN00x machines in a combined role
# using both profile::dns::recursor and profile::ntp (and in the future,
# profile::dns::auth as well, plus a little bit of inter-service glue)
class profile::dnsbox {
    include ::profile::standard
    include ::profile::dns::recursor
    include ::profile::ntp
}
