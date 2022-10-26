# = Class: role::puppetmaster::standalone
#
# Sets up a standalone puppetmaster, without frontend/backend
# separation.
#
# Useful only on wmcs VMs.
#
# == Parameters
#
# [*autosign*]
#  Set to true to have puppetmaster automatically accept all
#  certificate signing requests. Note that if you want to
#  keep any secrets secure in your puppetmaster, you *can not*
#  use this, and will have to sign manually.
#
# [*prevent_cherrypicks*]
#  Set to true to prevent manual cherry-picking / modification of
#  the puppet git repository. Is accomplished using git hooks.
#
# [*git_sync_minutes*]
#  How frequently should the git repositories be sync'd to upstream.
#  Defaults to 10.
#
# [*extra_auth_rules*]
#  A string that gets added to auth.conf as extra auth rules for
#  the puppetmaster.
#
# [*server_name*]
#  Hostname for the puppetmaster. Defaults to fqdn. Is used for SSL
#  certificates, virtualhost routing, etc
#
# [*enable_geoip*]
#  Enable/disable provisioning ::puppetmaster::geoip for serving clients who
#  use the ::geoip::data::puppet class in their manifests.
#  Default: false
#
# [*realm_override*]
#   this is use to override the realm used for the facts upload. its only really
#   used if you have two puppet masters in the same projects servicing different
#   clients e.g. cloudinfra

class role::puppetmaster::standalone(
    Boolean                                  $autosign            = false,
    Boolean                                  $prevent_cherrypicks = false,
    Integer[1,30]                            $git_sync_minutes    = 10,
    Optional[String]                         $extra_auth_rules    = undef,
    Stdlib::Host                             $server_name         = $facts['fqdn'],
    Boolean                                  $enable_geoip        = false,
    Boolean                                  $use_r10k            = false,
    Boolean                                  $upload_facts        = false,
    Hash[String, Puppetmaster::R10k::Source] $r10k_sources        = {},
    Optional[String[1]]                      $realm_override      = undef,
) {
    system::role { 'puppetmaster::standalone':
        description => 'Cloud VPS project puppetmaster',
    }

    include profile::openstack::base::puppetmaster::enc_client
    include profile::openstack::base::puppetmaster::stale_certs_exporter

    $base_config = {
        'node_terminus'     => 'exec',
        'external_nodes'    => '/usr/local/bin/puppet-enc',
        'thin_storeconfigs' => false,
        'autosign'          => $autosign,
    }

    class {'profile::puppetmaster::common':
        base_config        => $base_config,
        disable_env_config => $use_r10k,
    }

    $config = $profile::puppetmaster::common::storeconfigs == 'puppetdb' ? {
        true    => $profile::puppetmaster::common::config + { 'thin_storeconfigs' => true },
        default => $profile::puppetmaster::common::config
    }

    class { 'httpd':
        remove_default_ports => true,
        modules              => [
            'proxy',
            'proxy_http',
            'proxy_balancer',
            'passenger',
            'rewrite',
            'lbmethod_byrequests',
        ],
    }
    ensure_packages('libapache2-mod-passenger')

    class { 'puppetmaster':
        server_name         => $server_name,
        secure_private      => false,
        prevent_cherrypicks => $prevent_cherrypicks,
        extra_auth_rules    => $extra_auth_rules,
        config              => $config,
        enable_geoip        => $enable_geoip,
        hiera_config        => $profile::puppetmaster::common::hiera_config,
        use_r10k            => $use_r10k,
        r10k_sources        => $r10k_sources,
        upload_facts        => $upload_facts,
        realm_override      => $realm_override,
    }

    # Update git checkout
    class { 'puppetmaster::gitsync':
        run_every_minutes => $git_sync_minutes,
    }

    ferm::service { 'puppetmaster-standalone':
        proto  => 'tcp',
        port   => 8140,
        srange => '$LABS_NETWORKS',
    }
}
