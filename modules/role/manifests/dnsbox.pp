# Combo role for configuring production dnsN00x machines with recursive DNS,
# authoritative DNS, and NTP.
class role::dnsbox {
    system::role { 'dnsbox': description => 'DNS auth/recursor and NTP Site Infra Server' }

    include profile::base::production
    include profile::ntp
    include profile::dns::auth
    include profile::dns::recursor

}
