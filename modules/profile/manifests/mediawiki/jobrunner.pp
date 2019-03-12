class profile::mediawiki::jobrunner(
    $statsd = hiera('statsd'),
    Optional[Wmflib::UserIpPort] $fcgi_port = hiera('profile::php_fpm::fcgi_port', undef),
    String $fcgi_pool = hiera('profile::mediawiki::fcgi_pool', 'www'),
) {
    # Parameters we don't need to override
    $port = 9005
    $local_only_port = 9006
    $fcgi_proxy = mediawiki::fcgi_endpoint($fcgi_port, $fcgi_pool)

    # Add headers lost by mod_proxy_fastcgi
    # The apache module doesn't pass along to the fastcgi appserver
    # a few headers, like Content-Type and Content-Length.
    # We need to add them back here.
    ::httpd::conf { 'fcgi_headers':
        source   => 'puppet:///modules/mediawiki/apache/configs/fcgi_headers.conf',
        priority => 0,
    }
    # Declare the proxies explicitly with retry=0
    httpd::conf { 'fcgi_proxies':
        ensure  => present,
        content => template('mediawiki/apache/fcgi_proxies.conf.erb')
    }



    class { '::httpd':
        period  => 'daily',
        rotate  => 7,
        modules => [
            'alias',
            'authz_host',
            'autoindex',
            'deflate',
            'dir',
            'expires',
            'headers',
            'mime',
            'rewrite',
            'setenvif',
            'proxy_fcgi',
        ]
    }

    class { '::httpd::mpm':
        mpm => 'worker',
    }

    # Modules we don't enable.
    # TODO: We should also disable auth_basic, authn_file, authz_user
    # env, negotiation and reqtimeout
    ::httpd::mod_conf { [
        'authz_default',
        'authz_groupfile',
        'cgi',
    ]:
        ensure => absent,
    }

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

    httpd::conf { 'hhvm_jobrunner_port':
        priority => 1,
        content  => inline_template("# This file is managed by Puppet\nListen <%= @port %>\nListen <%= @local_only_port %>\n"),
    }

    httpd::site{ 'hhvm_jobrunner':
        priority => 1,
        content  => template('profile/mediawiki/jobrunner/site.conf.erb'),
    }

    # HHVM admin interface
    class { '::hhvm::admin': }


    ::monitoring::service { 'jobrunner_http_hhvm':
        description   => 'HHVM jobrunner',
        check_command => 'check_http_jobrunner',
        retries       => 2,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Jobrunner',
    }

    # TODO: restrict this to monitoring and localhost only.
    ::ferm::service { 'mediawiki-jobrunner':
        proto   => 'tcp',
        port    => $port,
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
    }
}
