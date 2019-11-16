# at some point this class should inherit all the code currently present
# in profile::openstack::base::keystone::db
class profile::openstack::codfw1dev::db(
    Stdlib::Fqdn        $cloudcontrol_fqdn = lookup('profile::openstack::codfw1dev::nova_controller'),
    Stdlib::Fqdn        $cloudcontrol_standby_fqdn = lookup('profile::openstack::codfw1dev::nova_controller_standby'),
    Stdlib::Fqdn        $cloudservices_fqdn = lookup('profile::openstack::codfw1dev::designate_host'),
    Stdlib::Fqdn        $cloudservices_standby_fqdn = lookup('profile::openstack::codfw1dev::designate_host_standby'),
    Stdlib::Fqdn        $puppetmaster = lookup('profile::openstack::codfw1dev::puppetmaster::web_hostname'),
    Stdlib::Compat::Array $labweb_hosts = lookup('profile::openstack::codfw1dev::labweb_hosts'),
    Array[Stdlib::Fqdn] $prometheus_nodes  = lookup('prometheus_nodes'),
    Array[String] $mysql_root_clients = hiera('mysql_root_clients', []),
    Array[String] $maintenance_hosts = hiera('maintenance_hosts'),
) {
    include ::profile::standard

    package {'mysql-server':
        ensure => 'present',
    }

    file {'/etc/mysql/my.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///modules/profile/openstack/codfw1dev/db/my.cnf',
        require => Package['mysql-server'],
    }

    prometheus::mysqld_exporter { 'default':
        client_password => '',
        client_socket   => '/var/run/mysqld/mysqld.sock',
    }

    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    ferm::service { 'prometheus-mysqld-exporter':
        proto  => 'tcp',
        port   => '9104',
        srange => "@resolve((${prometheus_ferm_nodes}))",
    }

    ferm::rule { 'cloudcontrol_mysql':
        ensure => 'present',
        rule   => "saddr (@resolve(${cloudcontrol_fqdn}) @resolve(${cloudcontrol_fqdn}, AAAA) @resolve(${cloudcontrol_standby_fqdn}) @resolve(${cloudcontrol_standby_fqdn}, AAAA) @resolve(${cloudservices_fqdn}, AAAA) @resolve(${cloudservices_fqdn}, AAAA) @resolve(${cloudservices_standby_fqdn}, AAAA) @resolve(${cloudservices_standby_fqdn}, AAAA)  @resolve(${puppetmaster}) @resolve(${puppetmaster}, AAAA)) proto tcp dport (3306) ACCEPT;",
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
