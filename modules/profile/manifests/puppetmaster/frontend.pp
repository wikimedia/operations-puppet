# @summray  config puppetmaster frontends
# @param config addtional config to use
# @param secure_private If false, /etc/puppet/private will be labs/private.git.
#   Otherwise, some magic is done to have local repositories and sync between puppetmasters.
# @param web_hostname hostname of the website
# @param ca_server the CA server
# @param ca_source source of the CA file
# @param manage_ca_file if true manage the CA file
# @param swift_clusters instance of Swift::Clusters (hash of cluster info)
# @param prevent_cherrypicks disable cherry picks
# @param monitor_signed_certs if true monitor signed certs for expiry
# @param extra_auth_rules Addtional auth rules
# @param signed_certs_warning Warn if agent certs are due to expire within this time
# @param signed_certs_critical Critical alert if agent certs are due to expire within this time
# @param canary_hosts list of hosts used for caanary testing
# @param servers list of puppetmaster backend servers with wieghts
# @param ssl_ca_revocation_check the type of SSL revocation check to perform
# @param http_proxy the HTTP proxy if one is required
# @param mcrouter_ca_secret The secret for mcrouter CA
class profile::puppetmaster::frontend(
    # Globals
    Stdlib::Host        $ca_server               = lookup('puppet_ca_server'),
    Stdlib::Filesource  $ca_source               = lookup('puppet_ca_source'),
    Boolean             $manage_ca_file          = lookup('manage_puppet_ca_file'),
    Optional[Stdlib::HTTPUrl] $http_proxy        = lookup('http_proxy'),
    Swift::Clusters     $swift_clusters          = lookup('swift_clusters'),
    # Class scope
    # TODO: we should probably configure theses in P:puppetmaster::common
    Hash[String, Puppetmaster::Backends] $servers        = lookup('puppetmaster::servers'),
    # Locals
    Hash                          $config                  = lookup('profile::puppetmaster::frontend::config'),
    Boolean                       $secure_private          = lookup('profile::puppetmaster::frontend::secure_private'),
    String                        $web_hostname            = lookup('profile::puppetmaster::frontend::web_hostname'),
    Boolean                       $prevent_cherrypicks     = lookup('profile::puppetmaster::frontend::prevent_cherrypicks'),
    Boolean                       $monitor_signed_certs    = lookup('profile::puppetmaster::frontend::monitor_signed_certs'),
    Integer                       $signed_certs_warning    = lookup('profile::puppetmaster::frontend::signed_certs_warning'),
    Integer                       $signed_certs_critical   = lookup('profile::puppetmaster::frontend::signed_certs_critical'),
    Array[Stdlib::Host]           $canary_hosts            = lookup('profile::puppetmaster::frontend::canary_hosts'),
    Enum['chain', 'leaf', 'none'] $ssl_ca_revocation_check = lookup('profile::puppetmaster::frontend::ssl_ca_revocation_check'),
    Optional[String]              $extra_auth_rules        = lookup('profile::puppetmaster::frontend::extra_auth_rules'),
    Optional[String[1]]           $mcrouter_ca_secret      = lookup('profile::puppetmaster::frontend::mcrouter_ca_secret'),
) {
    ensure_packages([
      'libapache2-mod-passenger',
      'age'  # useful file encryption tool, modern gpg replacement
    ])

    backup::set { 'var-lib-puppet-ssl': }
    backup::set { 'var-lib-puppet-volatile': }
    if $manage_ca_file {
        file{[$facts['puppet_config']['master']['localcacert'],
              "${facts['puppet_config']['master']['ssldir']}/ca/ca_crt.pem"]:
            ensure => file,
            owner  => 'puppet',
            group  => 'puppet',
            source => $ca_source,
        }
    }
    # Puppet frontends are git masters at least for their datacenter
    $ca = $ca_server == $facts['networking']['fqdn']
    $sync_ensure = $ca.bool2str('absent', 'present')
    # The master frontend copies updated swift rings from each clusters'
    # ring management host into volatile
    $ring_fetch = $ca.bool2str('present', 'absent')

    if $ca {
        # Ensure cergen is present for managing TLS keys and
        # x509 certificates signed by the Puppet CA.
        class { 'cergen': }
        if $mcrouter_ca_secret {
            class { 'cergen::mcrouter_ca':
                ca_secret => $mcrouter_ca_secret,
            }
        }

        # Ship cassandra-ca-manager (precursor of cergen)
        class { 'cassandra::ca_manager': }

        # Ensure nagios can read the signed certs
        $signed_cert_path = "${facts['puppet_config']['master']['ssldir']}/ca/signed"
        file {$signed_cert_path:
            ensure  => directory,
            owner   => 'puppet',
            group   => 'puppet',
            mode    => '0644',
            recurse => true,
        }

        $monitor_ensure = ($monitor_signed_certs and $ca).bool2str('present', 'absent')
        nrpe::plugin { 'nrpe_check_puppetca_expired_certs':
            ensure => $monitor_ensure,
            source => 'puppet:///modules/profile/puppetmaster/nrpe_check_puppetca_expired_certs.sh',
        }

        nrpe::monitor_service {'puppetca_expired_certs':
            ensure         => $monitor_ensure,
            description    => 'Puppet CA expired certs',
            check_interval => 60,  # minutes
            timeout        => 60,  # seconds
            nrpe_command   => "/usr/local/lib/nagios/plugins/nrpe_check_puppetca_expired_certs ${signed_cert_path} ${signed_certs_warning} ${signed_certs_critical}",
            notes_url      => 'https://wikitech.wikimedia.org/wiki/Puppet#Renew_agent_certificate',
        }
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

    $swift_clusters.each |String $sc, Swift::Cluster_info $sc_info| {
        if $sc_info['ring_manager'] != undef {
            systemd::timer::job { "fetch-rings-${sc}":
                ensure                    => $ring_fetch,
                user                      => 'root',
                description               => "rsync swift rings from cluster ${sc}",
                command                   => "/usr/bin/rsync -bcptz ${sc_info['ring_manager']}::swiftrings/new_rings.tar.bz2 /var/lib/puppet/volatile/swift/${sc_info['cluster_name']}/",
                interval                  => {'start' => 'OnCalendar', 'interval' => '*:5/20:00'},
                monitoring_enabled        => true,
                monitoring_contact_groups => 'databases-testing',
                logging_enabled           => false,
            }
        }
    }

    ferm::service { 'puppetmaster-frontend':
        srange => '$DOMAIN_NETWORKS',
        proto  => 'tcp',
        port   => 8140,
    }

    $puppetmaster_frontend_ferm = join(keys($servers), ' ')
    ferm::service { 'ssh_puppet_merge':
        proto  => 'tcp',
        port   => '22',
        srange => "(@resolve((${servers.keys.join(' ')})))",
    }

    ferm::service { 'rsync_puppet_frontends':
        proto  => 'tcp',
        port   => '873',
        srange => "(@resolve((${servers.keys.join(' ')})))",
    }
    ferm::service { 'puppetmaster-backend':
        proto  => 'tcp',
        port   => 8141,
        srange => "(@resolve((${servers.keys.join(' ')})))",
    }

    # Let's download the public cloud IP ranges, save them to etcd.
    # This will only upload to conftool on the CA puppetmaster.
    class { 'external_clouds_vendors':
        ensure      => 'present',
        user        => 'root',
        manage_user => false,
        conftool    => $ca,
        outfile     => '/var/lib/puppet/volatile/external_cloud_vendors/public_clouds.json',
        http_proxy  => $http_proxy,
    }
}
# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab smarttab
