class profile::openstack::base::puppetmaster::backend(
    $labs_instance_range = hiera('profile::openstack::base::nova::fixed_range'),
    $horizon_host = hiera('profile::openstack::base::horizon_host'),
    $designate_host = hiera('profile::openstack::base::designate_host'),
    $puppetmaster_webhostname = hiera('profile::openstack::base::puppetmaster::web_hostname'),
    $puppetmaster_hostname = hiera('profile::openstack::base::puppetmaster_hostname'),
    $puppetmaster_ca = hiera('profile::openstack::base::puppetmaster::ca'),
    $puppetmasters = hiera('profile::openstack::base::puppetmaster::servers'),
    $baremetal_servers = hiera('profile::openstack::base::puppetmaster::baremetal'),
    $encapi_db_host = hiera('profile::openstack::base::puppetmaster::encapi::db_host'),
    $encapi_db_name = hiera('profile::openstack::base::puppetmaster::encapi::db_name'),
    $encapi_db_user = hiera('profile::openstack::base::puppetmaster::encapi::db_user'),
    $encapi_db_pass = hiera('profile::openstack::base::puppetmaster::encapi::db_pass'),
    $encapi_statsd_prefix = hiera('profile::openstack::base::puppetmaster::encapi::statsd_prefix'),
    $statsd_host = hiera('profile::openstack::base::statsd_host'),
    ) {

    require ::profile::conftool::client
    include ::network::constants
    class {'profile::openstack::base::puppetmaster::common':
        labs_instance_range      => $labs_instance_range,
        horizon_host             => $horizon_host,
        designate_host           => $designate_host,
        puppetmaster_webhostname => $puppetmaster_webhostname,
        puppetmaster_hostname    => $puppetmaster_hostname,
        puppetmasters            => $puppetmasters,
        baremetal_servers        => $baremetal_servers,
        encapi_db_host           => $encapi_db_host,
        encapi_db_name           => $encapi_db_name,
        encapi_db_user           => $encapi_db_user,
        encapi_db_pass           => $encapi_db_pass,
        encapi_statsd_prefix     => $encapi_statsd_prefix,
        statsd_host              => $statsd_host,
    }

    # Only allow puppet access from the instances
    $allow_from = flatten([$labs_instance_range, $baremetal_servers, '.wikimedia.org'])

    $config = {
        'node_terminus'     => 'exec',
        'external_nodes'    => '/usr/local/bin/puppet-enc',
        'thin_storeconfigs' => false,
        'autosign'          => true,
    }

    # urls are different in v4 so we need to modify our auth rules accordingly
    $puppet_major_version = hiera('puppet_major_version', 3)
    $extra_auth_rules_template = $puppet_major_version ? {
        4       => 'extra_auth_rules_v4.conf.erb',
        default => 'extra_auth_rules.conf.erb',
    }

    class { '::profile::puppetmaster::backend':
        config           => $config,
        secure_private   => false,
        allow_from       => $allow_from,
        puppetmasters    => $puppetmasters,
        ca_server        => $puppetmaster_ca,
        extra_auth_rules => template("profile/openstack/base/puppetmaster/${extra_auth_rules_template}"),
    }
}
