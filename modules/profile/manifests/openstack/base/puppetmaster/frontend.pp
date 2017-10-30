class profile::openstack::base::puppetmaster::frontend(
    $prevent_cherrypick = hiera('profile::openstack::base::puppetmaster::frontend::prevent_cherrypicks'),
    $labs_instance_range = hiera('profile::openstack::base::nova::fixed_range'),
    $horizon_host = hiera('profile::openstack::base::horizon_host'),
    $designate_host = hiera('profile::openstack::base::designate_host'),
    $puppetmasters = hiera('profile::openstack::base::puppetmaster::servers'),
    $puppetmaster_ca = hiera('profile::openstack::base::puppetmaster::ca'),
    $puppetmaster_hostname = hiera('profile::openstack::base::puppetmaster_hostname'),
    $puppetmaster_webhostname = hiera('profile::openstack::base::puppetmaster::web_hostname'),
    $baremetal_servers = hiera('profile::openstack::base::puppetmaster::baremetal'),
    $encapi_db_host = hiera('profile::openstack::base::puppetmaster::encapi::db_host'),
    $encapi_db_name = hiera('profile::openstack::base::puppetmaster::encapi::db_name'),
    $encapi_db_user = hiera('profile::openstack::base::puppetmaster::encapi::db_user'),
    $encapi_db_pass = hiera('profile::openstack::base::puppetmaster::encapi::db_pass'),
    $encapi_statsd_prefix = hiera('profile::openstack::base::puppetmaster::encapi::statsd_prefix'),
    $statsd_host = hiera('profile::openstack::base::statsd_host'),
    ) {

    include ::network::constants
    include ::profile::backup::host
    include ::profile::conftool::client
    include ::profile::conftool::master
    # config-master.wikimedia.org
    include ::profile::configmaster
    include ::profile::discovery::client

    # validatelabsfqdn will look up an instance certname in nova
    #  and make sure it's for an actual instance before signing
    file { '/usr/local/sbin/validatelabsfqdn.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/puppetmaster/validatelabsfqdn.py',
    }

    class {'profile::openstack::base::puppetmaster::common':
        labs_instance_range   => $labs_instance_range,
        horizon_host          => $horizon_host,
        designate_host        => $designate_host,
        puppetmaster_hostname => $puppetmaster_hostname,
        puppetmasters         => $puppetmasters,
        baremetal_servers     => $baremetal_servers,
        encapi_db_host        => $encapi_db_host,
        encapi_db_name        => $encapi_db_name,
        encapi_db_user        => $encapi_db_user,
        encapi_db_pass        => $encapi_db_pass,
        encapi_statsd_prefix  => $encapi_statsd_prefix,
        statsd_host           => $statsd_host,
    }

    if ! defined(Class['puppetmaster::certmanager']) {
        class { 'puppetmaster::certmanager':
            remote_cert_cleaner => $designate_host,
        }
    }

    $config = {
        'node_terminus'     => 'exec',
        'external_nodes'    => '/usr/local/bin/puppet-enc',
        'thin_storeconfigs' => false,
        'autosign'          => '/usr/local/sbin/validatelabsfqdn.py',
    }

    class { '::profile::puppetmaster::frontend':
        ca_server        => $puppetmaster_ca,
        web_hostname     => $puppetmaster_webhostname,
        config           => $config,
        secure_private   => false,
        servers          => $puppetmasters,
        extra_auth_rules => template('profile/openstack/base/puppetmaster/extra_auth_rules.conf.erb'),
    }

    ferm::rule{'puppetmaster_balancer':
        ensure => 'present',
        rule   => "saddr (${labs_instance_range} ${baremetal_servers}
                          @resolve(${horizon_host}) @resolve(${horizon_host}, AAAA))
                          proto tcp dport 8140 ACCEPT;",
    }

    ferm::rule{'puppetcertcleaning':
        ensure => 'present',
        rule   => "saddr (@resolve(${designate_host}))
                        proto tcp dport 22 ACCEPT;",
    }
}
