class profile::openstack::base::puppetmaster::backend(
    $designate_host = hiera('profile::openstack::base::designate_host'),
    $second_region_designate_host = hiera('profile::openstack::base::second_region_designate_host'),
    $puppetmaster_webhostname = hiera('profile::openstack::base::puppetmaster::web_hostname'),
    $puppetmaster_hostname = hiera('profile::openstack::base::puppetmaster_hostname'),
    $puppetmaster_ca = hiera('profile::openstack::base::puppetmaster::ca'),
    $puppetmasters = hiera('profile::openstack::base::puppetmaster::servers'),
    $encapi_db_host = hiera('profile::openstack::base::puppetmaster::encapi::db_host'),
    $encapi_db_name = hiera('profile::openstack::base::puppetmaster::encapi::db_name'),
    $encapi_db_user = hiera('profile::openstack::base::puppetmaster::encapi::db_user'),
    $encapi_db_pass = hiera('profile::openstack::base::puppetmaster::encapi::db_pass'),
    $encapi_statsd_prefix = hiera('profile::openstack::base::puppetmaster::encapi::statsd_prefix'),
    $statsd_host = hiera('profile::openstack::base::statsd_host'),
    $labweb_hosts = hiera('profile::openstack::base::labweb_hosts'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    ) {

    require ::profile::conftool::client
    include ::network::constants
    class {'profile::openstack::base::puppetmaster::common':
        designate_host               => $designate_host,
        second_region_designate_host => $second_region_designate_host,
        puppetmaster_webhostname     => $puppetmaster_webhostname,
        puppetmaster_hostname        => $puppetmaster_hostname,
        puppetmasters                => $puppetmasters,
        encapi_db_host               => $encapi_db_host,
        encapi_db_name               => $encapi_db_name,
        encapi_db_user               => $encapi_db_user,
        encapi_db_pass               => $encapi_db_pass,
        encapi_statsd_prefix         => $encapi_statsd_prefix,
        statsd_host                  => $statsd_host,
        labweb_hosts                 => $labweb_hosts,
        nova_controller              => $nova_controller,
    }

    # Only allow puppet access from the instances
    $labs_networks = join($network::constants::labs_networks, ' ')
    $allow_from = flatten([$network::constants::labs_networks, '.wikimedia.org'])

    $config = {
        'node_terminus'     => 'exec',
        'external_nodes'    => '/usr/local/bin/puppet-enc',
        'thin_storeconfigs' => false,
        'autosign'          => true,
    }

    class { '::profile::puppetmaster::backend':
        config           => $config,
        secure_private   => false,
        allow_from       => $allow_from,
        puppetmasters    => $puppetmasters,
        ca_server        => $puppetmaster_ca,
        extra_auth_rules => template('profile/openstack/base/puppetmaster/extra_auth_rules.conf.erb'),
    }
}
