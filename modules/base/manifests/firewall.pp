# Don't include this sub class on all hosts yet
# NOTE: Policy is DROP by default
class base::firewall {
    include ::network::constants
    include ::ferm

    $defscontent = $::realm ? {
        'labs'  => template('base/firewall/defs.erb', 'base/firewall/defs.labs.erb'),
        default => template('base/firewall/defs.erb'),
    }
    ferm::conf { 'defs':
        prio    => '00',
        content => $defscontent,
    }

    # Increase the size of conntrack table size (default is 65536)
    sysctl::parameters { 'ferm_conntrack':
        values => {
            'net.netfilter.nf_conntrack_max'                   => 262144,
            'net.netfilter.nf_conntrack_tcp_timeout_time_wait' => 65,
        },
    }

    # The sysctl value net.netfilter.nf_conntrack_buckets is read-only. It is configured
    # via a modprobe parameter, bump it manually for running systems
    exec { 'bump nf_conntrack hash table size':
        command => '/bin/echo 32768 > /sys/module/nf_conntrack/parameters/hashsize',
        onlyif  => "/bin/grep --invert-match --quiet '^32768$' /sys/module/nf_conntrack/parameters/hashsize",
    }

    ferm::conf { 'main':
        prio   => '00',
        source => 'puppet:///modules/base/firewall/main-input-default-drop.conf',
    }

    ferm::rule { 'bastion-ssh':
        rule   => 'proto tcp dport ssh saddr $BASTION_HOSTS ACCEPT;',
    }

    ferm::rule { 'monitoring-all':
        rule   => 'saddr $MONITORING_HOSTS ACCEPT;',
    }

    if $::realm == 'production' {
        ::ferm::service { 'ssh-from-cumin-masters':
            proto  => 'tcp',
            port   => '22',
            srange => '$CUMIN_MASTERS',
        }
    }

    file { '/usr/lib/nagios/plugins/check_conntrack':
        source => 'puppet:///modules/base/firewall/check_conntrack.py',
        mode   => '0755',
    }

    nrpe::monitor_service { 'conntrack_table_size':
        description   => 'Check size of conntrack table',
        nrpe_command  => '/usr/lib/nagios/plugins/check_conntrack 80 90',
        require       => File['/usr/lib/nagios/plugins/check_conntrack'],
        contact_group => 'admins',
    }

    sudo::user { 'nagios_check_ferm':
        user       => 'nagios',
        privileges => [ 'ALL = NOPASSWD: /usr/lib/nagios/plugins/check_ferm' ],
        require    => File['/usr/lib/nagios/plugins/check_ferm'],
    }

    file { '/usr/lib/nagios/plugins/check_ferm':
        source => 'puppet:///modules/base/firewall/check_ferm',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    nrpe::monitor_service { 'ferm_active':
        description   => 'Check whether ferm is active by checking the default input chain',
        nrpe_command  => '/usr/bin/sudo /usr/lib/nagios/plugins/check_ferm',
        require       =>  [File['/usr/lib/nagios/plugins/check_ferm'], Sudo::User['nagios_check_ferm']],
        contact_group => 'admins',
    }
}
