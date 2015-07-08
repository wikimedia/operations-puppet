# Don't include this sub class on all hosts yet
# NOTE: Policy is DROP by default
class base::firewall($ensure = 'present') {
    include network::constants
    include ferm

    $defscontent = $::realm ? {
        'labs'  => template('base/firewall/defs.erb', 'base/firewall/defs.labs.erb'),
        default => template('base/firewall/defs.erb'),
    }
    ferm::conf { 'defs':
        # defs can always be present.
        # They don't actually do firewalling.
        ensure  => 'present',
        prio    => '00',
        content => $defscontent,
    }

    ferm::conf { 'main':
        ensure => $ensure,
        prio   => '00',
        source => 'puppet:///modules/base/firewall/main-input-default-drop.conf',
    }

    ferm::rule { 'bastion-ssh':
        ensure => $ensure,
        rule   => 'proto tcp dport ssh saddr $BASTION_HOSTS ACCEPT;',
    }

    ferm::rule { 'monitoring-all':
        ensure => $ensure,
        rule   => 'saddr $MONITORING_HOSTS ACCEPT;',
    }

    file { '/usr/lib/nagios/plugins/check_conntrack':
        source => 'puppet:///modules/base/firewall/check_conntrack.py',
        mode   => '0755',
    }

    nrpe::monitor_service { 'conntrack_table_size':
        ensure        => 'present',
        description   => 'Check size of conntrack table',
        nrpe_command  => '/usr/lib/nagios/plugins/check_conntrack -w 80 -c 90',
        require       => File['/usr/lib/nagios/plugins/check_conntrack'],
        contact_group => 'admins',
    }
}
