# == Class standard::ntp::timesyncd
#
# Setup clock synchronisation using systemd-timesyncd
class standard::ntp::timesyncd () {
    requires_os('debian >= jessie')
    require standard::ntp

    package { 'ntp':
        ensure => absent,
    }

    $wmf_peers = $::standard::ntp::wmf_peers
    # This maps the servers that regular clients use
    $ntp_servers = {
        eqiad => concat($wmf_peers['eqiad'], $wmf_peers['codfw']),
        codfw => concat($wmf_peers['eqiad'], $wmf_peers['codfw']),
        esams => concat($wmf_peers['esams'], $wmf_peers['eqiad']),
        ulsfo => concat($wmf_peers['eqiad'], $wmf_peers['codfw']),
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

    monitoring::service { 'ntp':
        description    => 'NTP',
        check_command  => 'check_ntp_time!0.5!1',
        check_interval => 30,
        retry_interval => 15,
    }

}

