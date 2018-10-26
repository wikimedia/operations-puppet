class profile::openstack::base::puppetmaster::frontend(
    $designate_host = hiera('profile::openstack::base::designate_host'),
    $second_region_designate_host = hiera('profile::openstack::base::second_region_designate_host'),
    $puppetmasters = hiera('profile::openstack::base::puppetmaster::servers'),
    $puppetmaster_ca = hiera('profile::openstack::base::puppetmaster::ca'),
    $puppetmaster_hostname = hiera('profile::openstack::base::puppetmaster_hostname'),
    $puppetmaster_webhostname = hiera('profile::openstack::base::puppetmaster::web_hostname'),
    $encapi_db_host = hiera('profile::openstack::base::puppetmaster::encapi::db_host'),
    $encapi_db_name = hiera('profile::openstack::base::puppetmaster::encapi::db_name'),
    $encapi_db_user = hiera('profile::openstack::base::puppetmaster::encapi::db_user'),
    $encapi_db_pass = hiera('profile::openstack::base::puppetmaster::encapi::db_pass'),
    $encapi_statsd_prefix = hiera('profile::openstack::base::puppetmaster::encapi::statsd_prefix'),
    $statsd_host = hiera('profile::openstack::base::statsd_host'),
    $labweb_hosts = hiera('profile::openstack::base::labweb_hosts'),
    $cert_secret_path = hiera('profile::openstack::base::puppetmaster::cert_secret_path'),
    $nova_controller = hiera('profile::openstack::base::nova_controller'),
    ) {

    include ::network::constants
    include ::profile::backup::host
    include ::profile::conftool::client
    include ::profile::conftool::master

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

    if ! defined(Class['puppetmaster::certmanager']) {
        $cleaner1_ip = ipresolve($designate_host, 4)
        $cleaner1_ip6 = ipresolve($designate_host, 6)
        $cleaner2_ip = ipresolve($second_region_designate_host, 4)
        $cleaner2_ip6 = ipresolve($second_region_designate_host, 6)
        class { 'puppetmaster::certmanager':
            remote_cert_cleaners => "${cleaner1_ip},${cleaner1_ip6},${cleaner2_ip},${cleaner2_ip6}"
        }
    }

    $config = {
        'node_terminus'     => 'exec',
        'external_nodes'    => '/usr/local/bin/puppet-enc',
        'thin_storeconfigs' => false,
        'autosign'          => '/usr/local/sbin/validatelabsfqdn.py',
    }

    # urls are different in v4 so we need to modify our auth rules accordingly
    $puppet_major_version = hiera('puppet_major_version', 3)
    $extra_auth_rules_template = $puppet_major_version ? {
        4       => 'extra_auth_rules_v4.conf.erb',
        default => 'extra_auth_rules.conf.erb',
    }

    class { '::profile::puppetmaster::frontend':
        ca_server          => $puppetmaster_ca,
        web_hostname       => $puppetmaster_webhostname,
        config             => $config,
        secure_private     => false,
        servers            => $puppetmasters,
        extra_auth_rules   => template("profile/openstack/base/puppetmaster/${extra_auth_rules_template}"),
        mcrouter_ca_secret => false,
    }

    # The above profile will make a standard vhost for $web_hostname.
    #  We also want to support clients using simple 'puppet'
    #   as the master name.  There's some DNS magic elsewhere
    #   so that VMs can refer to 'puppet' and get a deployment-appropriate
    #   puppetmaster.
    ::puppetmaster::web_frontend { 'puppet':
        master           => $puppetmaster_ca,
        workers          => $puppetmasters[$::fqdn],
        bind_address     => $::puppetmaster::bind_address,
        priority         => 40,
        cert_secret_path => $cert_secret_path,
    }

    $labs_networks = join($network::constants::labs_networks, ' ')
    $labweb_ips = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>))")
    $labweb_ips_v6 = inline_template("@resolve((<%= @labweb_hosts.join(' ') %>), AAAA)")
    ferm::rule{'puppetmaster_balancer':
        ensure => 'present',
        rule   => "saddr (${labs_networks}
                          ${labweb_ips} ${labweb_ips_v6})
                          proto tcp dport 8140 ACCEPT;",
    }

    ferm::rule{'puppetcertcleaning':
        ensure => 'present',
        rule   => "saddr (@resolve((${designate_host} ${second_region_designate_host}))
                         @resolve((${designate_host} ${second_region_designate_host}), AAAA))
                        proto tcp dport 22 ACCEPT;",
    }
}
