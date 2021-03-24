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
# [*hiera_config*]
#  Allows to select from a range of hiera.yaml files in modules/puppetmaster/files.
#  Typically the $::realm default works, but in e.g. codfw1dev this should
#  be specified to pick up the right config.
#
# [*enable_geoip*]
#  Enable/disable provisioning ::puppetmaster::geoip for serving clients who
#  use the ::geoip::data::puppet class in their manifests.
#  Default: false
#
# filtertags: labs-common
class role::puppetmaster::standalone(
                                $autosign = false,
    Boolean                     $prevent_cherrypicks = false,
    Array[Stdlib::IP::Address]  $allow_from = ['10.0.0.0/8', '172.16.0.0/21'],
    Integer[1,30]               $git_sync_minutes = 10,
    String                      $extra_auth_rules = '',
    Stdlib::Host                $server_name = $::fqdn,
    Stdlib::Host                $labs_puppet_master = lookup('labs_puppet_master'),
                                $storeconfigs = false,
    Boolean                     $enable_geoip = false,
    Boolean                     $command_broadcast = false,
    String[1]                   $hiera_config = $::realm,
    Optional[Variant[Array[Stdlib::Host], Stdlib::Host]] $puppetdb_host = undef,
) {
    $puppetdb_hosts = ($puppetdb_host =~ Stdlib::Host) ? {
        true    => [$puppetdb_host],
        default => $puppetdb_host,
    }

    class {'openstack::puppet::master::enc':
        puppetmaster => $labs_puppet_master,
    }

    $env_config = {
        'environmentpath'  => '$confdir/environments',
        'default_manifest' => '$confdir/manifests',
    }

    $base_config = {
        'node_terminus'     => 'exec',
        'external_nodes'    => '/usr/local/bin/puppet-enc',
        'thin_storeconfigs' => false,
        'autosign'          => $autosign,
    }

    $puppetdb_config = {
        storeconfigs         => true,
        thin_storeconfigs    => true,
        storeconfigs_backend => 'puppetdb',
        reports              => 'puppetdb',
    }

    if $storeconfigs == 'puppetdb' {
        if debian::codename::le('stretch') {
            apt::repository { 'wikimedia-puppetdb4':
                uri        => 'http://apt.wikimedia.org/wikimedia',
                dist       => "${::lsbdistcodename}-wikimedia",
                components => 'component/puppetdb4',
                before     => Class['puppetmaster::puppetdb::client'],
            }
        }
        class { 'puppetmaster::puppetdb::client':
            hosts             => $puppetdb_hosts,
            command_broadcast => $command_broadcast,
        }
        $config = merge($base_config, $puppetdb_config, $env_config)
    } else {
        $config = merge($base_config, $env_config)
    }

    class { 'httpd':
        modules => ['proxy',
                    'proxy_http',
                    'proxy_balancer',
                    'passenger',
                    'rewrite',
                    'lbmethod_byrequests'],
    }
    ensure_packages('libapache2-mod-passenger')

    class { 'puppetmaster':
        server_name         => $server_name,
        allow_from          => $allow_from,
        secure_private      => false,
        prevent_cherrypicks => $prevent_cherrypicks,
        extra_auth_rules    => $extra_auth_rules,
        config              => $config,
        enable_geoip        => $enable_geoip,
        hiera_config        => $hiera_config,
    }

    # Don't attempt to use puppet-master service, we're using passenger.
    service { 'puppet-master':
        ensure  => stopped,
        enable  => false,
        require => Package['puppet'],
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
