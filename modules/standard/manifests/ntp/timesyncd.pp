# == Class standard::ntp::timesyncd
#
# Setup clock synchronisation using systemd-timesyncd
class standard::ntp::timesyncd () {
    require standard::ntp

    package { 'ntp':
        ensure => purged,
    }

    # This maps the servers that regular clients use
    $ntp_servers = {
        eqiad => concat($::ntp_peers['eqiad'], $::ntp_peers['codfw']),
        codfw => concat($::ntp_peers['eqiad'], $::ntp_peers['codfw']),
        esams => concat($::ntp_peers['esams'], $::ntp_peers['eqiad']),
        ulsfo => concat($::ntp_peers['ulsfo'], $::ntp_peers['codfw']),
        eqsin => concat($::ntp_peers['eqsin'], $::ntp_peers['codfw']),
    }

    file { '/etc/systemd/timesyncd.conf':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('base/timesyncd.conf.erb'),
        notify  => Service['systemd-timesyncd'],
    }

    service { 'systemd-timesyncd':
        ensure   => running,
        provider => systemd,
        enable   => true,
    }

    base::service_auto_restart { 'systemd-timesyncd': }

    file { '/usr/lib/nagios/plugins/check_timedatectl':
        source => 'puppet:///modules/base/check_timedatectl',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    nrpe::monitor_service { 'timesynd_ntp_status':
        ensure         => 'present',
        description    => 'Check the NTP synchronisation status of timesyncd',
        nrpe_command   => '/usr/lib/nagios/plugins/check_timedatectl',
        require        => File['/usr/lib/nagios/plugins/check_timedatectl'],
        contact_group  => 'admins',
        check_interval => 30,
    }
}
