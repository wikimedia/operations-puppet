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
    include role::mariadb::monitor::dba
    include role::mariadb::ferm

    # Note:  This will install mariadb but won't set up the
    #  pdns database.  Manual steps are:
    #
    #  $ /opt/wmf/mariadb/scripts/mysql_install_db
    #  Then export the 'pdns' db from a working labservices host and import
    #  Then, run 'designate-manage powerdns sync' for the new host
    #
    class { 'mariadb::packages_wmf':
        package => 'wmf-mariadb10',
    }

    class { 'mariadb::service':
        ensure  => running,
        package => 'wmf-mariadb10',
        manage  => true,
        enable  => true,
    }

    class { 'mariadb::config':
        config    => 'role/mariadb/mysqld_config/dns.my.cnf.erb',
        datadir   => '/srv/sqldata',
        tmpdir    => '/srv/tmp',
        read_only => 'off',
    }

    package { 'mysql-client':
        ensure => present,
    }

    $pdns_db_password       = $dnsconfig['db_pass']
    $pdns_admin_db_password = $dnsconfig['db_admin_pass']
    $designate_host = ipresolve(hiera('labs_designate_hostname'), 4)
    file { '/etc/mysql/production-grants-dns.sql':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        content => template('role/mariadb/grants/dns.sql.erb'),
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

    # Allow mysql access from the designate host so it can send domain updates.
    ferm::service { 'mysql_designate':
        proto  => 'tcp',
        port   => '3306',
        srange => $designate_host,
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
        description   => 'Check for gridmaster host resolution UDP',
        check_command => "check_dig!${auth_soa_name}!tools-grid-master.tools.eqiad.wmflabs",
    }

    monitoring::service { "${auth_soa_name} Auth DNS TCP":
        host          => $auth_soa_name,
        description   => 'Check for gridmaster host resolution TCP',
        check_command => "check_dig_tcp!${auth_soa_name}!tools-grid-master.tools.eqiad.wmflabs",
    }
}
