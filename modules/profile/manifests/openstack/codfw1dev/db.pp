# at some point this class should inherit all the code currently present
# in profile::openstack::base::keystone::db
class profile::openstack::codfw1dev::db(
    Stdlib::Fqdn        $cloudcontrol_fqdn = lookup('profile::openstack::codfw1dev::nova_controller'),
    Stdlib::Fqdn        $cloudcontrol_standby_fqdn = lookup('profile::openstack::codfw1dev::nova_controller_standby'),
    Array[Stdlib::Fqdn] $prometheus_nodes  = lookup('prometheus_nodes'),
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
        rule   => "saddr (@resolve(${cloudcontrol_fqdn}) @resolve(${cloudcontrol_fqdn}, AAAA) @resolve(${cloudcontrol_standby_fqdn}) @resolve(${cloudcontrol_standby_fqdn}, AAAA) ) proto tcp dport (3306) ACCEPT;",
    }
}
