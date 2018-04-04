# === Class mediawiki::web
#
# Installs and configures a web environment for mediawiki
class mediawiki::web {
    tag 'mediawiki', 'mw-apache-config'

    include ::apache
    include ::mediawiki
    include ::mediawiki::users

    include ::mediawiki::web::modules
    include ::mediawiki::web::mpm_config


    file { '/etc/apache2/apache2.conf':
        content => template('mediawiki/apache/apache2.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Service['apache2'],
        require => Package['apache2'],
    }

    # Starting with stretch libapache2-mod-security2 includes the following
    # in /etc/apache2/mods-enabled/security2.conf:
    #   # Include OWASP ModSecurity CRS rules if installed
    #   IncludeOptional /usr/share/modsecurity-crs/owasp-crs*.load
    # The directory /usr/share/modsecurity-crs is shipped by the
    # modsecurity-crs package, but it's only a Recommends: of
    # libapache2-mod-security2, so it doesn'get installed. And IncludeOptional
    # is only optional for the full path, so if /usr/share/modsecurity-crs doesn't
    # exist, it bails out and apache refuses to start/restart. As such, ship an
    # empty directory to make that include truly optional
    # In addition IncludeOptional expects a wildcard (which the original config
    # from modsecurity-crs doesn't ship, so we also need to ship an empty
    # stub config
    # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=878920
    # https://bz.apache.org/bugzilla/show_bug.cgi?id=57585
    # Once we're running a version of the patch proposed in Apache bugzilla, this
    # workaround can be removed
    if os_version('debian >= stretch') {
        file { '/usr/share/modsecurity-crs':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0775',
            before => File['/usr/share/modsecurity-crs/owasp-crs.load'],
        }
        file { '/usr/share/modsecurity-crs/owasp-crs.load':
            owner   => 'root',
            content => '',
            group   => 'root',
            mode    => '0444',
            before  => Service['apache2'],
        }
    }

    # The apache2 systemd unit in stretch enables PrivateTmp by default
    # This makes "systemctl reload apache" fail with error code 226/EXIT_NAMESPACE
    # (which is a failure to setup a mount namespace). This is specific to our
    # mediawiki setup:
    # Normally, with PrivateTmp enabled, /tmp would appear as
    # /tmp/systemd-private-$ID-apache2.service-$RANDOM and /var/tmp would appear as
    # /var/tmp/systemd-private-$ID-apache2.service-$RANDOM. That works fine for
    # /var/tmp, but fails for /tmp (so the reload only exposes the issue)
    #
    # This is most definitely caused by HHVM in some way (although I have been
    # unable to pinpoint where exactly). Per systemd unit ordering both start up
    # in parallel and lsof -a +L1 /tmp/ shows e.g. references to deleted file
    # handles owned by HHVM processed running under www-data.
    #
    # Disable PrivateTmp on stretch, it causes disruptions for stretch-based setups
    # and we can revisit this when phasing out HHVM, with firejail being used for
    # command execution from mediawiki we're isolated those executions to a private
    # file namespace anyway.
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
            content => "[Service]\nPrivateTmp=false\n"
            notify  => Exec['systemctl-daemon-reload'],
        }

        exec { 'systemctl-daemon-reload':
            command     => '/bin/systemctl daemon-reload',
            refreshonly => true,
        }
    }

    file { '/var/lock/apache2':
        ensure => directory,
        owner  => $::mediawiki::users::web,
        group  => 'root',
        mode   => '0755',
        before => File['/etc/apache2/apache2.conf'],
    }

    apache::env { 'chuid_apache':
        vars => {
            'APACHE_RUN_USER'  => $::mediawiki::users::web,
            'APACHE_RUN_GROUP' => $::mediawiki::users::web,
        },
    }


    # Not needed anymore. TODO: remove at a later stage
    apache::def { 'HHVM':
        ensure => absent,
    }

    # Set the Server response header to be equal to the app server FQDN.
    include ::apache::mod::security2

    apache::conf { 'server_header':
        content  => template('mediawiki/apache/server-header.conf.erb'),
    }
}
