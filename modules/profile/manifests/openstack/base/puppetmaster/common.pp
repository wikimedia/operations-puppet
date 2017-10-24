class profile::openstack::base::puppetmaster::common(
    $labs_instance_range,
    $horizon_host,
    $designate_host,
    $puppetmaster_hostname,
    $puppetmasters,
    $baremetal_servers,
    $encapi_db_host,
    $encapi_db_name,
    $encapi_db_user,
    $encapi_db_pass,
    $encapi_statsd_prefix,
    $statsd_host,
    ) {

    # array of puppetmasters
    $all_puppetmasters = inline_template('<%= @puppetmasters.values.flatten(1).map { |p| p[\'worker\'] }.sort.join(\' \')%>')
    $baremetal_servers_str = inline_template('<%= @baremetal_servers.join " " %>')

    include ::puppetmaster::labsrootpass

    class {'::openstack2::puppet::master::enc':
        puppetmaster => $puppetmaster_hostname,
    }

    class { '::openstack2::puppet::master::encapi':
        mysql_host     => $encap_db_host,
        mysql_db       => $encap_db_name,
        mysql_username => $encap_db_user,
        mysql_password => $encap_db_pass,
        statsd_host    => $statsd_host,
        statsd_prefix  => $encap_statsd_prefix,
    }

    # Update git checkout.  This is done via a cron
    #  rather than via puppet_merge to increase isolation
    #  between these puppetmasters and the production ones.
    class { 'puppetmaster::gitsync':
        run_every_minutes => '1',
    }

    ferm::rule{'puppetmaster':
        ensure => 'present',
        rule   => "saddr (${labs_instance_range} ${baremetal_servers_str}
                          @resolve(${horizon_host}) @resolve(${horizon_host}, AAAA)
                          @resolve((${all_puppetmasters})))
                          proto tcp dport 8141 ACCEPT;",
    }

    ferm::rule{'puppetbackend':
        ensure => 'present',
        rule   => "saddr (@resolve(${horizon_host}) @resolve(${designate_host})
                          @resolve(${horizon_host}, AAAA))
                          proto tcp dport 8101 ACCEPT;",
    }

    ferm::rule{'puppetbackendgetter':
        ensure => 'present',
        rule   => "saddr (${labs_instance_range} ${baremetal_servers_str}
                   @resolve(${horizon_host}) @resolve(${horizon_host}, AAAA)
                   @resolve((${all_puppetmasters})) @resolve((${all_puppetmasters}), AAAA))
                   proto tcp dport 8100 ACCEPT;",
    }
}
