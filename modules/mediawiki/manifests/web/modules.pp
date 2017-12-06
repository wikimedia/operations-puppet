class mediawiki::web::modules {
    include ::apache::mod::alias
    include ::apache::mod::authz_host
    include ::apache::mod::autoindex
    include ::apache::mod::dir
    include ::apache::mod::expires
    include ::apache::mod::headers
    include ::apache::mod::mime
    include ::apache::mod::rewrite
    include ::apache::mod::setenvif
    include ::apache::mod::status

    # Include the apache configurations for php
    include ::mediawiki::web::php_engine

    # Modules we don't enable.
    # Note that deflate and filter are activated deep down in the
    # apache sites, we should probably move them here
    apache::mod_conf { [
        'auth_basic',
        'authn_file',
        'authz_default',
        'authz_groupfile',
        'authz_user',
        'cgi',
        'deflate',
        'env',
        'negotiation',
        'reqtimeout',
    ]:
        ensure => absent,
    }

    file { '/etc/apache2/mods-available/expires.conf':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/modules/expires.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        before => Class['::apache::mod::expires'],
    }

    file { '/etc/apache2/mods-available/autoindex.conf':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/modules/autoindex.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        before => Class['::apache::mod::autoindex'],
    }


    file { '/etc/apache2/mods-available/setenvif.conf':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/modules/setenvif.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['apache2'],
    }

    file { '/etc/apache2/mods-available/mime.conf':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/modules/mime.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['apache2'],
    }

    # TODO: remove this? It's not used anywhere AFAICT
    file { '/etc/apache2/mods-available/userdir.conf':
        ensure => present,
        source => 'puppet:///modules/mediawiki/apache/modules/userdir.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    # mod_security2 configuration
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
    class { '::apache::mod::security2': }
}
