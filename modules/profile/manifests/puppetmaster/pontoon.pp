class profile::puppetmaster::pontoon (
    Integer[1,30]                 $git_sync_minutes = lookup('profile::puppetmaster::pontoon::git_sync_minutes', {'default_value' => 10}),
    String                        $storeconfigs = lookup('profile::puppetmaster::common::storeconfigs', {'default_value' => '' }),
    Optional[Array[Stdlib::Host]] $puppetdb_hosts = lookup('profile::puppetmaster::common::puppetdb_hosts', {'default_value' => undef}),
) {
    ensure_packages('libapache2-mod-passenger')
    class { 'pontoon::enc': }

    class { 'cergen': }
    class { 'profile::java': }

    # Generating all service certificates can take a long time.
    # Therefore run cert generation only when a load balancer is deployed, this
    # saves time during stack bootstrap.
    if (!$::pontoon_bootstrap and pontoon::hosts_for_role('pontoon::lb') != undef) {
        $tls_services = wmflib::service::fetch().filter |$name, $config| {
            ('encryption' in $config and $config['encryption'])
        }

        class { 'pontoon::service_certs':
            ca_server       => pontoon::hosts_for_role('puppetmaster::pontoon')[0],
            services_config => $tls_services,
        }
    }

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
        # Wait for puppetdb to be ready before enabling server support.
        #
        # The probing is necessary to resolve a bootstrap race between server and db:
        # * puppetdb settings (puppetdb.yaml) are enabled in Pontoon
        # * the puppetdb host has not yet completed its bootstrap/initialization
        # * puppet runs on the server host and enables puppetdb
        # At this point the server has enabled a broken puppetdb and all future puppet runs will
        # fail (including all puppet runs needed by puppetdb to finish bootstrapping, thus requiring
        # a manual intervention to break the race)
        # Therefore enable puppetdb only when we're reasonably sure the server won't self-sabotage.
        exec { 'probe puppetdb':
            # The jq "inputs |" form is to exit non-zero on empty input
            command => @("PROBER"/L)
            /usr/bin/curl --fail --silent \
              --cacert /etc/ssl/certs/Puppet_Internal_CA.pem \
              'https://${puppetdb_hosts[0]}/status/v1/services/puppetdb-status' \
              | jq -ne 'inputs | .state == "running"'
            | - PROBER
            ,
            creates => '/etc/puppet/routes.yaml', # Probe only if puppetdb::client hasn't completed
        }

        class { 'puppetmaster::puppetdb::client':
            hosts   => $puppetdb_hosts,
            require => Exec['probe puppetdb'],
        }
        $config = merge($base_config, $puppetdb_config, $env_config)
    } else {
        $config = merge($base_config, $env_config)
    }

    class { 'httpd':
        listen_ports => [],
        modules      => ['proxy', 'proxy_http', 'proxy_balancer',
                        'passenger', 'rewrite', 'lbmethod_byrequests'],
    }

    class { 'puppetmaster':
        server_name         => $::fqdn,
        allow_from          => ['10.0.0.0/8', '172.16.0.0/21'],
        secure_private      => false,
        prevent_cherrypicks => false,
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
        srange => '$DOMAIN_NETWORKS',
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
