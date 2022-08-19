class profile::openstack::codfw1dev::db(
    Array[Stdlib::Fqdn] $labweb_hosts = lookup('profile::openstack::codfw1dev::labweb_hosts'),
    Array[Stdlib::IP::Address] $mysql_root_clients = lookup('mysql_root_clients', {default_value => []}),
    Array[Stdlib::IP::Address] $maintenance_hosts = lookup('maintenance_hosts'),
) {

    package {'wmf-mariadb104':
        ensure => 'present',
    }

    # TODO: consider using profile::pki::get_cert
    # This creates also /etc/mysql/ssl
    puppet::expose_agent_certs { '/etc/mysql':
        ensure          => present,
        provide_private => true,
        user            => 'mysql',
        group           => 'mysql',
    }

    file {'/etc/mysql/my.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/profile/openstack/codfw1dev/db/my.cnf',
        require => Package['wmf-mariadb104'],
    }

    prometheus::mysqld_exporter { 'default':
        client_password => '',
        client_socket   => '/var/run/mysqld/mysqld.sock',
    }

    ferm::rule { 'labweb_mysql':
        ensure => 'present',
        rule   => "saddr (@resolve((${labweb_hosts.join(' ')}))) proto tcp dport (3306) ACCEPT;",
    }

    # mysql monitoring and administration from root clients/tendril
    $mysql_root_clients_str = join($mysql_root_clients, ' ')
    ferm::service { 'mysql_admin_standard':
        proto  => 'tcp',
        port   => '3306',
        srange => "(${mysql_root_clients_str})",
    }
    ferm::service { 'mysql_admin_alternative':
        proto  => 'tcp',
        port   => '3307',
        srange => "(${mysql_root_clients_str})",
    }

    # mysql from deployment master servers and maintenance hosts (T98682, T109736)
    $maintenance_hosts_str = join($maintenance_hosts, ' ')
    ferm::service { 'mysql_deployment_mwmaint':
        proto  => 'tcp',
        port   => '3306',
        srange => "(\$DEPLOYMENT_HOSTS ${maintenance_hosts_str})",
    }

}
