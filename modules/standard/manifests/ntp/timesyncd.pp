# == Class standard::ntp::timesyncd
#
# Setup clock synchronisation using systemd-timesyncd
class standard::ntp::timesyncd () {
    requires_os('debian >= jessie')
    require standard::ntp

    package { 'ntp':
        ensure => purged,
    }

    $wmf_peers = $::standard::ntp::wmf_peers
    # This maps the servers that regular clients use
    $ntp_servers = {
        eqiad => concat($wmf_peers['eqiad'], $wmf_peers['codfw']),
        codfw => concat($wmf_peers['eqiad'], $wmf_peers['codfw']),
        esams => concat($wmf_peers['esams'], $wmf_peers['eqiad']),
        ulsfo => concat($wmf_peers['ulsfo'], $wmf_peers['codfw']),
        eqsin => concat($wmf_peers['eqsin'], $wmf_peers['codfw']),
    }

    file { '/etc/systemd/timesyncd.conf':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('base/timesyncd.conf.erb'),
        notify  => Service['systemd-timesyncd'],
    }

    # The diamond collector is specific to ISC ntpd and not useful with timesyncd, T157794
    diamond::collector { 'Ntpd':
        ensure => 'absent',
    }

    service { 'systemd-timesyncd':
        ensure   => running,
        provider => systemd,
        enable   => true,
    }

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
