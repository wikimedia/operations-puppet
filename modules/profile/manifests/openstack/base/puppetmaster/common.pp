class profile::openstack::base::puppetmaster::common(
    $labs_instance_range = hiera('profile::openstack::base::puppetmaster::common::labs_instance_range'),
    $designate_host = hiera('profile::openstack::base::puppetmaster::common::designate_host'),
    $puppetmaster_webhostname = hiera('profile::openstack::base::puppetmaster::web_hostname'),
    $puppetmaster_hostname = hiera('profile::openstack::base::puppetmaster::common::puppetmaster_hostname'),
    $puppetmasters = hiera('profile::openstack::base::puppetmaster::common::puppetmasters'),
    $baremetal_servers = hiera('profile::openstack::base::puppetmaster::common::baremetal_servers'),
    $encapi_db_host = hiera('profile::openstack::base::puppetmaster::common::encapi_db_host'),
    $encapi_db_name = hiera('profile::openstack::base::puppetmaster::common::encapi_db_name'),
    $encapi_db_user = hiera('profile::openstack::base::puppetmaster::common::encapi_db_user'),
    $encapi_db_pass = hiera('profile::openstack::base::puppetmaster::common::encapi_db_pass'),
    $encapi_statsd_prefix = hiera('profile::openstack::base::puppetmaster::common::encapi_statsd_prefix'),
    $statsd_host = hiera('profile::openstack::base::puppetmaster::common::statsd_host'),
    $labweb_hosts = hiera('profile::openstack::base::labweb_hosts'),
    ) {

    # array of puppetmasters
    $all_puppetmasters = inline_template('<%= @puppetmasters.values.flatten(1).map { |p| p[\'worker\'] }.sort.join(\' \')%>')
    $baremetal_servers_str = inline_template('<%= @baremetal_servers.join " " %>')

    class {'::puppetmaster::labsrootpass':}

    class {'::openstack::puppet::master::enc':
        puppetmaster => $puppetmaster_webhostname,
    }

    class { '::openstack::puppet::master::encapi':
        mysql_host          => $encapi_db_host,
        mysql_db            => $encapi_db_name,
        mysql_username      => $encapi_db_user,
        mysql_password      => $encapi_db_pass,
        statsd_host         => $statsd_host,
        statsd_prefix       => $encapi_statsd_prefix,
        labs_instance_range => $labs_instance_range,
        puppetmasters       => $puppetmasters,
        labweb_hosts        => $labweb_hosts,
    }

    # Update git checkout.  This is done via a cron
    #  rather than via puppet_merge to increase isolation
    #  between these puppetmasters and the production ones.
    class { 'puppetmaster::gitsync':
        run_every_minutes => '1',
    }

    $labweb_ips = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>))")
    $labweb_aaaa = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>), AAAA)")

    ferm::rule{'puppetmaster':
        ensure => 'present',
        rule   => "saddr (${labs_instance_range} ${baremetal_servers_str}
                          @resolve((${all_puppetmasters})) ${labweb_ips} ${labweb_aaaa})
                          proto tcp dport 8141 ACCEPT;",
    }

    ferm::rule{'puppetbackend':
        ensure => 'present',
        rule   => "saddr (@resolve(${designate_host})
                          ${labweb_ips} ${labweb_aaaa})
                          proto tcp dport 8101 ACCEPT;",
    }

    ferm::rule{'puppetbackendgetter':
        ensure => 'present',
        rule   => "saddr (${labs_instance_range} ${baremetal_servers_str}
                          ${labweb_ips} ${labweb_aaaa}
                          @resolve((${all_puppetmasters})) @resolve((${all_puppetmasters}), AAAA))
                          proto tcp dport 8100 ACCEPT;",
    }
}
