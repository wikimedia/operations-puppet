# Combo role for configuring production dnsN00x machines with recursive DNS,
# authoritative DNS, and NTP.
class role::dnsbox {
    include profile::base::production
    include profile::ntp
    include profile::dns::auth
    include profile::dns::recursor
}
