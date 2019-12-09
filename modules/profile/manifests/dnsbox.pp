# Combo profile for configuring production dnsN00x machines in a combined role
# for recursive DNS, authoritative DNS, and NTP.
class profile::dnsbox(
    Boolean $include_auth = lookup('profile::dnsbox::include_auth', {default_value => false}),
) {
    include ::profile::dns::recursor
    include ::profile::ntp

    # The $include_auth mechanism is temporary as we progressively test and
    # roll out this setup to the dnsbox fleet.
    if $include_auth {
        include ::profile::dns::auth

        # This is the puppet-level glue, to ensure that it operates on these
        # services in the appropriate order to avoid unnecessary mayhem.
        Service['gdnsd'] -> Service['pdns-recursor']

        # This is the systemd-level glue to ensure pdns-recursor cannot be
        # running unless gdnsd is already running
        $sysd_glue = '/etc/systemd/system/pdns-recursor.service.d/rec-needs-auth.conf'
        file { $sysd_glue:
            ensure => present,
            mode   => '0444',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/profile/dnsbox/rec-needs-auth.conf',
        }
        exec { 'systemd reload for rec-needs-auth glue':
            refreshonly => true,
            command     => '/bin/systemctl daemon-reload',
            subscribe   => File[$sysd_glue],
            before      => Service['pdns-recursor'],
            require     => Service['gdnsd'],
        }
    }
}
