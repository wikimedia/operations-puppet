# Don't include this sub class on all hosts yet
# NOTE: Policy is DROP by default
class base::firewall (
    Array[Stdlib::IP::Address] $cumin_masters = [],
    Array[Stdlib::IP::Address] $bastion_hosts = [],
    Array[Stdlib::IP::Address] $cache_hosts = [],
    Array[Stdlib::IP::Address] $kafka_brokers_main = [],
    Array[Stdlib::IP::Address] $kafka_brokers_analytics = [],
    Array[Stdlib::IP::Address] $kafka_brokers_jumbo = [],
    Array[Stdlib::IP::Address] $kafka_brokers_logging = [],
    Array[Stdlib::IP::Address] $zookeeper_hosts_main = [],
    Array[Stdlib::IP::Address] $hadoop_masters = [],
    Array[Stdlib::IP::Address] $druid_public_hosts = [],
) {
    include ::network::constants
    include ::ferm

    ferm::conf { 'defs':
        prio    => '00',
        content => template('base/firewall/defs.erb'),
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

    $bastion_hosts_str = join($bastion_hosts, ' ')
    ferm::rule { 'bastion-ssh':
        rule   => "proto tcp dport ssh saddr (${bastion_hosts_str}) ACCEPT;",
    }

    ferm::rule { 'monitoring-all':
        rule   => 'saddr $MONITORING_HOSTS ACCEPT;',
    }

    ::ferm::service { 'ssh-from-cumin-masters':
        proto  => 'tcp',
        port   => '22',
        srange => '$CUMIN_MASTERS',
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
