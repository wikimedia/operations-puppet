class profile::openstack::base::puppetmaster::backend(
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::base::designate_hosts'),
    $puppetmaster_webhostname = lookup('profile::openstack::base::puppetmaster::web_hostname'),
    $puppetmaster_hostname = lookup('profile::openstack::base::puppetmaster_hostname'),
    $puppetmaster_ca = lookup('profile::openstack::base::puppetmaster::ca'),
    $puppetmasters = lookup('profile::openstack::base::puppetmaster::servers'),
    $encapi_db_host = lookup('profile::openstack::base::puppetmaster::encapi::db_host'),
    $encapi_db_name = lookup('profile::openstack::base::puppetmaster::encapi::db_name'),
    $encapi_db_user = lookup('profile::openstack::base::puppetmaster::encapi::db_user'),
    $encapi_db_pass = lookup('profile::openstack::base::puppetmaster::encapi::db_pass'),
    $encapi_statsd_prefix = lookup('profile::openstack::base::puppetmaster::encapi::statsd_prefix'),
    $statsd_host = lookup('profile::openstack::base::statsd_host'),
    $labweb_hosts = lookup('profile::openstack::base::labweb_hosts'),
    ) {

    require ::profile::conftool::client
    include ::network::constants
    class {'profile::openstack::base::puppetmaster::common':
        openstack_controllers    => $openstack_controllers,
        designate_hosts          => $designate_hosts,
        puppetmaster_webhostname => $puppetmaster_webhostname,
        puppetmaster_hostname    => $puppetmaster_hostname,
        puppetmasters            => $puppetmasters,
        encapi_db_host           => $encapi_db_host,
        encapi_db_name           => $encapi_db_name,
        encapi_db_user           => $encapi_db_user,
        encapi_db_pass           => $encapi_db_pass,
        encapi_statsd_prefix     => $encapi_statsd_prefix,
        statsd_host              => $statsd_host,
        labweb_hosts             => $labweb_hosts,
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
        servers          => $puppetmasters,
        ca_server        => $puppetmaster_ca,
        extra_auth_rules => template('profile/openstack/base/puppetmaster/extra_auth_rules.conf.erb'),
    }
}
