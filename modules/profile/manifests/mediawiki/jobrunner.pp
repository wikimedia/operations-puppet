class profile::mediawiki::jobrunner(
    $statsd = hiera('statsd')
) {
    # Parameters we don't need to override
    $port = 9005
    $local_only_port = 9006

    # Special HHVM setup
    # The apache2 systemd unit in stretch enables PrivateTmp by default
    # This makes "systemctl reload apache" fail with error code 226/EXIT_NAMESPACE
    # (which is a failure to setup a mount namespace). This is specific to our
    # mediawiki setup:
    # Normally, with PrivateTmp enabled, /tmp would appear as
    # /tmp/systemd-private-$ID-apache2.service-$RANDOM and /var/tmp would appear as
    # /var/tmp/systemd-private-$ID-apache2.service-$RANDOM. That works fine for
    # /var/tmp, but fails for /tmp (so the reload only exposes the issue)
    #
    # Disable PrivateTmp on stretch, it prevents Apache reloads (as e.g. triggered by
    # logrorate) for current video scalers and we can revisit this when phasing out HHVM.
    #
    # To disable, ship a custom systemd override when running on stretch; we have
    # a cleaner mechanism to pass an override via systemd::unit, but that would require
    # extensive changes and since the mediawiki classes are up for major refactoring
    # soon, add this via simple file references for now
    if os_version('debian >= stretch') {
        file { '/etc/systemd/system/apache2.service.d':
            ensure => directory,
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }

        file { '/etc/systemd/system/apache2.service.d/override.conf':
            ensure  => present,
            mode    => '0755',
            owner   => 'root',
            group   => 'root',
            content => "[Service]\nPrivateTmp=false\n",
            notify  => Exec['mediawiki-jobrunner-apache-systemctl-override-daemon-reload'],
        }

        exec { 'mediawiki-jobrunner-apache-systemctl-override-daemon-reload':
            command     => '/bin/systemctl daemon-reload',
            refreshonly => true,
        }
    }

    class { '::apache::mpm':
        mpm => 'worker',
    }

    class { '::apache::mod::proxy_fcgi': }

    apache::conf { 'hhvm_jobrunner_port':
        priority => 1,
        content  => inline_template("# This file is managed by Puppet\nListen <%= @port %>\nListen <%= @local_only_port %>\n"),
    }

    apache::site{ 'hhvm_jobrunner':
        priority => 1,
        content  => template('profile/mediawiki/jobrunner/site.conf.erb'),
    }

    # HHVM admin interface
    class { '::hhvm::admin': }


    ::monitoring::service { 'jobrunner_http_hhvm':
        description   => 'HHVM jobrunner',
        check_command => 'check_http_jobrunner',
        retries       => 2,
    }

    # Monitor TCP Connection States
    ::diamond::collector { 'TcpConnStates':
        ensure => absent,
        source => 'puppet:///modules/diamond/collector/tcpconnstates.py',
    }

    # Monitor Ferm/Netfilter Connection Flows
    ::diamond::collector { 'NfConntrackCount':
        ensure => absent,
        source => 'puppet:///modules/diamond/collector/nf_conntrack_counter.py',
    }

    # TODO: restrict this to monitoring and localhost only.
    ::ferm::service { 'mediawiki-jobrunner':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
    }
}
