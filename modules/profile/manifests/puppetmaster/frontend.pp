# SPDX-License-Identifier: Apache-2.0
# @summray  config puppetmaster frontends
# @param config addtional config to use
# @param secure_private If false, /etc/puppet/private will be labs/private.git.
#   Otherwise, some magic is done to have local repositories and sync between puppetmasters.
# @param web_hostname hostname of the website
# @param ca_server the CA server
# @param prevent_cherrypicks disable cherry picks
# @param extra_auth_rules Addtional auth rules
# @param canary_hosts list of hosts used for caanary testing
# @param servers list of puppetmaster backend servers with wieghts
# @param ssl_ca_revocation_check the type of SSL revocation check to perform
# @param http_proxy the HTTP proxy if one is required
# @param ip_reputation_config The configuration of the ip reputation download script
# @param ip_reputation_proxies The list of proxy families to use in the ip reputation script
class profile::puppetmaster::frontend(
    # Globals
    Stdlib::Host        $ca_server               = lookup('puppet_ca_server'),
    Optional[Stdlib::HTTPUrl] $http_proxy        = lookup('http_proxy'),
    # Class scope
    # TODO: we should probably configure theses in P:puppetmaster::common
    Hash[String, Puppetmaster::Backends] $servers        = lookup('puppetmaster::servers'),
    Array[String] $puppetservers                         = lookup('profile::puppetmaster::frontend::puppetservers'),
    # Locals
    Hash                          $config                  = lookup('profile::puppetmaster::frontend::config'),
    Boolean                       $secure_private          = lookup('profile::puppetmaster::frontend::secure_private'),
    String                        $web_hostname            = lookup('profile::puppetmaster::frontend::web_hostname'),
    Boolean                       $prevent_cherrypicks     = lookup('profile::puppetmaster::frontend::prevent_cherrypicks'),
    Array[Stdlib::Host]           $canary_hosts            = lookup('profile::puppetmaster::frontend::canary_hosts'),
    Enum['chain', 'leaf', 'none'] $ssl_ca_revocation_check = lookup('profile::puppetmaster::frontend::ssl_ca_revocation_check'),
    Optional[String]              $extra_auth_rules        = lookup('profile::puppetmaster::frontend::extra_auth_rules'),
    # Should be defined in the private repo.
    Hash[String, Any]             $ip_reputation_config    = lookup('profile::puppetmaster::frontend::ip_reputation_config'),
    Array[String]                 $ip_reputation_proxies   = lookup('profile::puppetmaster::frontend::ip_reputation_proxies'),
    Optional[Stdlib::Host]        $puppet_merge_server     = lookup('puppet_merge_server'),
) {
    ensure_packages([
      'libapache2-mod-passenger',
      'age'  # useful file encryption tool, modern gpg replacement
    ])

    backup::set { 'var-lib-puppet-ssl': }
    backup::set { 'var-lib-puppet-volatile': }
    # Puppet frontends are git masters at least for their datacenter
    $ca = $ca_server == $facts['networking']['fqdn']
    $sync_ensure = $ca.bool2str('absent', 'present')

    if $ca {
        # Ensure cergen is present for managing TLS keys and
        # x509 certificates signed by the Puppet CA.
        class { 'cergen': }

        # TODO: this was set to let an NRPE check read the files
        # now that it's gone, we should check if a more strict
        # mode could be used
        $signed_cert_path = "${facts['puppet_config']['master']['ssldir']}/ca/signed"
        file {$signed_cert_path:
            ensure  => directory,
            owner   => 'puppet',
            group   => 'puppet',
            mode    => '0644',
            recurse => true,
        }
    }

    class { 'puppetmaster::ca_monitoring':
        ensure  => $ca.bool2str('present', 'absent'),
        ca_root => "${facts['puppet_config']['master']['ssldir']}/ca",
    }

    class { 'httpd':
        remove_default_ports => true,
        modules              => ['proxy', 'proxy_http', 'proxy_balancer',
                                'passenger', 'rewrite', 'lbmethod_byrequests'],
    }

    class { 'puppetmaster::ca_server':
        master => $ca_server,
    }

    $common_config = {
        'ca'              => $ca,
        'ca_server'       => $ca_server,
        'stringify_facts' => false,
    }

    $base_config = merge($config, $common_config)

    class { 'profile::puppetmaster::common':
        base_config => $base_config,
    }

    class { 'puppetmaster':
        bind_address        => '*',
        server_type         => 'frontend',
        is_git_master       => true,
        hiera_config        => $profile::puppetmaster::common::hiera_config,
        config              => $profile::puppetmaster::common::config,
        secure_private      => $secure_private,
        prevent_cherrypicks => $prevent_cherrypicks,
        extra_auth_rules    => $extra_auth_rules,
        ca_server           => $ca_server,
        ssl_verify_depth    => $profile::puppetmaster::common::ssl_verify_depth,
        servers             => $servers,
        upload_facts        => $ca, # We only want to upload from one place
        http_proxy          => $http_proxy,
        netbox_hiera_enable => $profile::puppetmaster::common::netbox_hiera_enable,
        enable_merge_cli    => $profile::puppetmaster::common::enable_merge_cli,
        puppet_merge_server => $puppet_merge_server,
    }

    $workers = $servers[$facts['networking']['fqdn']]
    # Main site to respond to
    puppetmaster::web_frontend { $web_hostname:
        master                  => $ca_server,
        workers                 => $workers,
        bind_address            => $puppetmaster::bind_address,
        priority                => 40,
        ssl_ca_revocation_check => $ssl_ca_revocation_check,
        canary_hosts            => $canary_hosts,
        ssl_verify_depth        => $profile::puppetmaster::common::ssl_verify_depth,
    }

    # On all the puppetmasters, we should respond
    # to the FQDN too, in case we point them explicitly
    puppetmaster::web_frontend { $facts['networking']['fqdn']:
        master                  => $ca_server,
        workers                 => $workers,
        bind_address            => $puppetmaster::bind_address,
        priority                => 50,
        ssl_ca_revocation_check => $ssl_ca_revocation_check,
        canary_hosts            => $canary_hosts,
        ssl_verify_depth        => $profile::puppetmaster::common::ssl_verify_depth,
    }

    # Run the rsync servers on all puppetmaster frontends, and activate
    # timer jobs syncing from the master
    class { 'puppetmaster::rsync':
        server      => $ca_server,
        sync_ensure => $sync_ensure,
        frontends   => keys($servers),
    }

    ferm::service { 'puppetmaster-frontend':
        srange => '$DOMAIN_NETWORKS',
        proto  => 'tcp',
        port   => 8140,
    }

    $puppetmaster_frontend_ferm = join(keys($servers), ' ')
    $puppetservers_puppetmasters_ferm = join($puppetservers + keys($servers), ' ')
    ferm::service { 'ssh_puppet_merge':
        proto  => 'tcp',
        port   => '22',
        srange => "(@resolve((${puppetservers_puppetmasters_ferm})))",
    }

    ferm::service { 'rsync_puppet_frontends':
        proto  => 'tcp',
        port   => '873',
        srange => "(@resolve((${puppetmaster_frontend_ferm})))",
    }
    ferm::service { 'puppetmaster-backend':
        proto  => 'tcp',
        port   => 8141,
        srange => "(@resolve((${puppetmaster_frontend_ferm})))",
    }

    # Let's download the public cloud IP ranges, save them to etcd.
    # This will only upload to conftool on the CA puppetmaster.
    class { 'external_clouds_vendors':
        ensure      => 'present',
        user        => 'root',
        manage_user => false,
        conftool    => false,
        outfile     => '/var/lib/puppet/volatile/external_cloud_vendors/public_clouds.json',
        http_proxy  => $http_proxy,
    }


    # Download the IP reputation data for consumption by
    # various parts of the infra.
    # It will be set to present if the list of reputation proxies to import isn't empty.
    class { 'ip_reputation_vendors':
        ensure         => $ip_reputation_proxies.empty().bool2str('absent', 'present'),
        user           => 'root',
        manage_user    => false,
        outfile        => '/var/lib/puppet/volatile/ip_reputation_vendors/proxies.json',
        proxy_families => $ip_reputation_proxies,
        configuration  => $ip_reputation_config,
        http_proxy     => $http_proxy,
    }


}
# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab smarttab
