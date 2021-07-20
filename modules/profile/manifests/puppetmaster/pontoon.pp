class profile::puppetmaster::pontoon (
    Integer[1,30]                 $git_sync_minutes = lookup('profile::puppetmaster::pontoon::git_sync_minutes', {'default_value' => 10}),
    Stdlib::Host                  $labs_puppet_master = lookup('labs_puppet_master'),
    String                        $storeconfigs = lookup('profile::puppetmaster::common::storeconfigs', {'default_value' => '' }),
    Optional[Array[Stdlib::Host]] $puppetdb_hosts = lookup('profile::puppetmaster::common::puppetdb_hosts', {'default_value' => undef}),
) {
    ensure_packages('libapache2-mod-passenger')
    class { 'pontoon::enc': }

    # Ensure the file is writable by 'puppet' user
    file { '/etc/puppet/hieradata/auto.yaml':
        ensure => present,
        owner  => 'puppet',
        group  => 'puppet',
        mode   => '0644',
    }

    # Make puppet_ssldir happy for self-hosted puppet
    file { '/var/lib/puppet/client':
        ensure => directory,
    }

    file { '/var/lib/puppet/client/ssl':
        ensure => link,
        target => '/var/lib/puppet/ssl',
    }

    $env_config = {
        'environmentpath'  => '$confdir/environments',
        'default_manifest' => '$confdir/manifests',
    }

    $base_config = {
        'node_terminus'     => 'exec',
        'external_nodes'    => '/usr/local/bin/puppet-enc --hiera.output /etc/puppet/hieradata/auto.yaml',
        'thin_storeconfigs' => false,
        'autosign'          => '/usr/local/bin/puppet-enc',
    }

    $puppetdb_config = {
        storeconfigs         => true,
        thin_storeconfigs    => true,
        storeconfigs_backend => 'puppetdb',
        reports              => 'puppetdb',
    }

    if $storeconfigs == 'puppetdb' {
        class { 'puppetmaster::puppetdb::client':
            hosts             => $puppetdb_hosts,
        }
        $config = merge($base_config, $puppetdb_config, $env_config)
    } else {
        $config = merge($base_config, $env_config)
    }

    class { 'httpd':
        remove_default_ports => true,
        modules              => ['proxy', 'proxy_http', 'proxy_balancer',
                                'passenger', 'rewrite', 'lbmethod_byrequests'],
    }

    class { 'puppetmaster':
        server_name         => $::fqdn,
        allow_from          => ['10.0.0.0/8', '172.16.0.0/21'],
        secure_private      => false,
        prevent_cherrypicks => false,
        extra_auth_rules    => '',
        config              => $config,
        enable_geoip        => false,
        hiera_config        => 'pontoon',
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

    ferm::service { 'puppetmaster-pontoon':
        proto  => 'tcp',
        port   => 8140,
        srange => '$LABS_NETWORKS',
    }

    # Fake confd using a file on disk.
    # Inspired by puppet_compiler module.
    file { '/etc/conftool-state':
        ensure => directory,
        mode   => '0755'
    }
    file { '/etc/conftool-state/mediawiki.yaml':
        ensure => present,
        mode   => '0444',
        source => 'puppet:///modules/puppet_compiler/mediawiki.yaml'
    }
}
