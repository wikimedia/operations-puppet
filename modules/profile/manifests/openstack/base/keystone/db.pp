class profile::openstack::base::keystone::db(
    $labs_hosts_range = hiera('profile::openstack::base::labs_hosts_range'),
    $puppetmaster_hostname = hiera('profile::openstack::base::puppetmaster_hostname'),
    $designate_host = hiera('profile::openstack::base::designate_host'),
    $horizon_host = hiera('profile::openstack::base::horizon_host'),
    $osm_host = hiera('profile::openstack::base::osm_host'),
    ) {

    package {'mysql-server':
        ensure => 'present',
    }

    file {'/etc/mysql/my.cnf':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('profile/openstack/base/keystone/db/my.cnf.erb'),
        require => Package['mysql-server'],
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

    ferm::rule{'mysql_designate':
        ensure => 'present',
        rule   => "saddr @resolve(${designate_host}) proto tcp dport (3306) ACCEPT;",
    }

    ferm::rule{'mysql_puppetmaster':
        ensure => 'present',
        rule   => "saddr @resolve(${puppetmaster_hostname}) proto tcp dport (3306) ACCEPT;",
    }

    ferm::rule{'mysql_horizon':
        ensure => 'present',
        rule   => "saddr @resolve(${horizon_host}) proto tcp dport (3306) ACCEPT;",
    }

    ferm::rule{'mysql_wikitech':
        ensure => 'present',
        rule   => "saddr @resolve(${osm_host}) proto tcp dport (3306) ACCEPT;",
    }

    # XXX: still needed?
    ferm::rule{'labspuppetbackend_horizon':
        ensure => 'present',
        rule   => "saddr @resolve(${horizon_host}) proto tcp dport (8100) ACCEPT;",
    }
}
