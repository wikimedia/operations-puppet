class profile::openstack::codfw1dev::db(
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::codfw1dev::openstack_controllers'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::codfw1dev::designate_hosts'),
    Stdlib::Fqdn        $puppetmaster = lookup('profile::openstack::codfw1dev::puppetmaster::web_hostname'),
    Stdlib::Compat::Array $labweb_hosts = lookup('profile::openstack::codfw1dev::labweb_hosts'),
    Array[String] $mysql_root_clients = lookup('mysql_root_clients', {default_value => []}),
    Array[String] $maintenance_hosts = lookup('maintenance_hosts'),
) {

    package {'mariadb-server':
        ensure => 'present',
    }

    file {'/etc/mysql/my.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/profile/openstack/codfw1dev/db/my.cnf',
        require => Package['mariadb-server'],
    }

    prometheus::mysqld_exporter { 'default':
        client_password => '',
        client_socket   => '/var/run/mysqld/mysqld.sock',
    }

    ferm::rule { 'cloudcontrol_mysql':
        ensure => 'present',
        rule   => "saddr (@resolve((${join($openstack_controllers,' ')})) @resolve((${join($openstack_controllers,' ')}), AAAA) @resolve((${join($designate_hosts,' ')})) @resolve((${join($designate_hosts,' ')}), AAAA) @resolve(${puppetmaster}) @resolve(${puppetmaster}, AAAA)) proto tcp dport (3306) ACCEPT;",
    }

    $labweb_ips = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>))")
    $labweb_ip6s = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>), AAAA)")
    ferm::rule { 'labweb_mysql':
        ensure => 'present',
        rule   => "saddr (${labweb_ips} ${labweb_ip6s}) proto tcp dport (3306) ACCEPT;",
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
