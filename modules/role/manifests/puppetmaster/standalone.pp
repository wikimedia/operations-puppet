# = Class: role::puppetmaster::standalone
#
# Sets up a standalone puppetmaster, without frontend/backend
# separation.
#
# Useful only in labs.
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
# [*allow_from*]
#  Array of CIDRs from which to allow access to this puppetmaster.
#  Defaults to the entire 10.x range, so no real access control.
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
# [*puppet_major_version*]
#  Distinguishes version of puppet software e.g. 3 or 4
#
# filtertags: labs-common
class role::puppetmaster::standalone(
    $autosign = false,
    $prevent_cherrypicks = false,
    $allow_from = ['10.0.0.0/8'],
    $git_sync_minutes = '10',
    $extra_auth_rules = '',
    $server_name = $::fqdn,
    $use_enc = true,
    $labs_puppet_master = hiera('labs_puppet_master'),
    $puppet_major_version = hiera('puppet_major_version', 3),
) {
    if ! $use_enc {
        fail('Ldap puppet node definitions are no longer supported.  The $use_enc param must be true.')
    }

    class {'::openstack::puppet::master::enc':
        puppetmaster => $labs_puppet_master,
    }

    $base_env_config = {
        'environmentpath'  => '$confdir/environments',
        'default_manifest' => '$confdir/manifests',
    }

    # Default to the future parser if on puppet 3
    if $puppet_major_version < 4 {
        $env_config = merge($base_env_config, {'parser' => 'future'})
    } else {
        $env_config = $base_env_config
    }


    $base_config = {
        'node_terminus'     => 'exec',
        'external_nodes'    => '/usr/local/bin/puppet-enc',
        'thin_storeconfigs' => false,
        'autosign'          => $autosign,
    }

    $config = merge($base_config, $env_config)

    class { '::puppetmaster':
        server_name          => $server_name,
        allow_from           => $allow_from,
        secure_private       => false,
        prevent_cherrypicks  => $prevent_cherrypicks,
        extra_auth_rules     => $extra_auth_rules,
        config               => $config,
        puppet_major_version => $puppet_major_version,
    }

    # Update git checkout
    class { 'puppetmaster::gitsync':
        run_every_minutes => $git_sync_minutes,
    }

    ferm::service { 'puppetmaster-frontend':
        proto  => 'tcp',
        port   => 8140,
        srange => '$DOMAIN_NETWORKS',
    }
}
