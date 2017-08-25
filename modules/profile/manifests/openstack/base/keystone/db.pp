class profile::openstack::base::keystone::db(
    $labs_hosts_range = hiera('profile::openstack::base::labs_hosts_range'),
    ) {

    package {'mysql-server':
        ensure => 'present',
    }

    # XXX: what purpose does this serve?
    ferm::service { 'mysql_iron':
        proto  => 'tcp',
        port   => '3306',
        srange => '@resolve(iron.wikimedia.org)',
    }

    # mysql monitoring access from tendril (db1011)
    ferm::service { 'mysql_tendril':
        proto  => 'tcp',
        port   => '3306',
        srange => '@resolve(tendril.wikimedia.org)',
    }

    ferm::rule{'mysql_nova':
        ensure => 'present',
        rule   => "saddr ${labs_hosts_range} proto tcp dport (3306) ACCEPT;",
    }
}
