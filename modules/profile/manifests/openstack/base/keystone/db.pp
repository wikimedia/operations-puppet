# this class is currently unused. Perhaps worth reallocating code
# to profile::openstack::codfw1dev::db
class profile::openstack::base::keystone::db(
    $labs_hosts_range = hiera('profile::openstack::base::labs_hosts_range'),
    $labs_hosts_range_v6 = hiera('profile::openstack::base::labs_hosts_range_v6'),
    $puppetmaster_hostname = hiera('profile::openstack::base::puppetmaster_hostname'),
    $designate_host = hiera('profile::openstack::base::designate_host'),
    $second_region_designate_host = hiera('profile::openstack::base::second_region_designate_host'),
    $osm_host = hiera('profile::openstack::base::osm_host'),
    ) {

    # mysql monitoring and administration from root clients/tendril
    $mysql_root_clients = join($::network::constants::special_hosts['production']['mysql_root_clients'], ' ')
    ferm::service { 'mysql_admin_standard':
        proto  => 'tcp',
        port   => '3306',
        srange => "(${mysql_root_clients})",
    }
    ferm::service { 'mysql_admin_alternative':
        proto  => 'tcp',
        port   => '3307',
        srange => "(${mysql_root_clients})",
    }

    ferm::rule{'mysql_nova':
        ensure => 'present',
        rule   => "saddr ${labs_hosts_range} proto tcp dport (3306) ACCEPT;",
    }

    ferm::rule{'mysql_nova_v6':
        ensure => 'present',
        rule   => "saddr ${labs_hosts_range_v6} proto tcp dport (3306) ACCEPT;",
    }

    ferm::rule{'mysql_designate':
        ensure => 'present',
        rule   => "saddr (@resolve((${designate_host} ${second_region_designate_host})) @resolve((${designate_host} ${second_region_designate_host}), AAAA)) proto tcp dport (3306) ACCEPT;",
    }

    ferm::rule{'mysql_puppetmaster':
        ensure => 'present',
        rule   => "saddr (@resolve(${puppetmaster_hostname}) @resolve(${puppetmaster_hostname}, AAAA)) proto tcp dport (3306) ACCEPT;",
    }

    ferm::rule{'mysql_wikitech':
        ensure => 'present',
        rule   => "saddr (@resolve(${osm_host}) @resolve(${osm_host}, AAAA)) proto tcp dport (3306) ACCEPT;",
    }
}
