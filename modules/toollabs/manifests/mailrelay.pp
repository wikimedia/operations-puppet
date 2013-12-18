# Class: toollabs::mailrelay
#
# This role sets up a mail relay in the Tool Labs model.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::mailrelay($maildomain) inherits toollabs {
    include toollabs::infrastructure

    package { 'procmail':
        ensure => present,
    }

    file { "${store}/mail-relay":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$store],
        content => template('toollabs/mail-relay.erb'),
    }

    File <| title == '/etc/exim4/exim4.conf' |> {
        source  => undef,
        content => template('toollabs/exim4.conf.erb'),
        notify  => Service['exim4'],
    }

    File <| title == '/etc/default/exim4' |> {
        content => undef,
        source  =>  'puppet:///modules/toollabs/exim4.default.mailrelay',
        notify  => Service['exim4'],
    }

    # Enable Ganglia monitoring.
    file { '/usr/local/bin/collect_exim_stats_via_gmetric':
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///files/ganglia/collect_exim_stats_via_gmetric',
    }

    cron { 'collect_exim_stats_via_gmetric':
        ensure  => present,
        user    => 'root',
        command => '/usr/local/bin/collect_exim_stats_via_gmetric',
        require => File['/usr/local/bin/collect_exim_stats_via_gmetric'],
    }
}

