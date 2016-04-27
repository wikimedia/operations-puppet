class role::labs::dns {

    system::role { 'role::labs::dns':
        description => 'DNS server for Labs instances',
    }

    $dnsconfig = hiera_hash('labsdnsconfig', {})

    class { '::labs_dns':
        dns_auth_ipaddress     => $::ipaddress_eth0,
        dns_auth_query_address => $::ipaddress_eth0,
        dns_auth_soa_name      => $dnsconfig['host'],
        pdns_db_host           => $dnsconfig['dbserver'],
        pdns_db_password       => $dnsconfig['db_pass'],
    }

    # install mysql locally on all dns servers
    include role::mariadb::grants
    include passwords::misc::scripts
    include role::mariadb::monitor::dba
    include role::mariadb::ferm

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    class { 'mariadb::config':
        prompt    => 'DNS',
        config    => 'mariadb/dns.my.cnf.erb',
        password  => $passwords::misc::scripts::mysql_root_pass,
        datadir   => '/srv/sqldata',
        tmpdir    => '/srv/tmp',
        read_only => 'off',
    }

    ferm::service { 'udp_dns_rec':
        proto => 'udp',
        port  => '53',
    }

    ferm::service { 'tcp_dns_rec':
        proto => 'tcp',
        port  => '53',
    }

    ferm::rule { 'skip_dns_conntrack-out':
        desc  => 'Skip DNS outgoing connection tracking',
        table => 'raw',
        chain => 'OUTPUT',
        rule  => 'proto udp sport 53 NOTRACK;',
    }

    ferm::rule { 'skip_dns_conntrack-in':
        desc  => 'Skip DNS incoming connection tracking',
        table => 'raw',
        chain => 'PREROUTING',
        rule  => 'proto udp dport 53 NOTRACK;',
    }

    sudo::user { 'diamond_sudo_for_pdns':
        user       => 'diamond',
        privileges => ['ALL=(root) NOPASSWD: /usr/bin/pdns_control list'],
    }

    # For the authoritative servers
    diamond::collector { 'PowerDNS':
        ensure   => present,
        settings => {
            # lint:ignore:quoted_booleans
            # This is jammed straight into a config file, needs quoting.
            use_sudo => 'true',
            # lint:endignore
        },
        require  => Sudo::User['diamond_sudo_for_pdns'],
    }

    sudo::user { 'diamond_sudo_for_pdns_recursor':
        user       => 'diamond',
        privileges => ['ALL=(root) NOPASSWD: /usr/bin/rec_control get-all'],
    }

    # For the recursor
    diamond::collector { 'PowerDNSRecursor':
        source   => 'puppet:///modules/diamond/collector/powerdns_recursor.py',
        settings => {
            # lint:ignore:quoted_booleans
            # This is jammed straight into a config file, needs quoting.
            use_sudo => 'true',
            # lint:endignore
        },
        require  => Sudo::User['diamond_sudo_for_pdns_recursor'],
    }

    $auth_soa_name = $dnsconfig['host']
    monitoring::host { $auth_soa_name:
        ip_address => $::ipaddress_eth0,
    }

    monitoring::service { "${auth_soa_name} Auth DNS UDP":
        host          => $auth_soa_name,
        description   => 'Check for gridmaster host resolution',
        check_command => "check_dig!${auth_soa_name}!tools-grid-master.tools.eqiad.wmflabs",
    }

    monitoring::service { "${auth_soa_name} Auth DNS TCP":
        host          => $auth_soa_name,
        description   => 'Check for gridmaster host resolution',
        check_command => "check_dig_tcp!${auth_soa_name}!tools-grid-master.tools.eqiad.wmflabs",
    }
}
