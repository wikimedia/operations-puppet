# Combo role for configuring production dnsN00x machines with recursive DNS,
# authoritative DNS, and NTP.
class role::dnsbox {
    system::role { 'dnsbox': description => 'DNS/NTP Site Infra Server' }

    include ::profile::standard
    include ::profile::ntp
    include ::profile::dns::auth
    class { '::profile::dns::recursor':
        # This glues pdns-recursor to gdnsd at the systemd level
        bind_service => 'gdnsd.service',
    }
    # This is the puppet-level glue, to ensure that it operates on these
    # services in the appropriate order to avoid unnecessary mayhem.
    Service['gdnsd'] -> Service['pdns-recursor']
}
