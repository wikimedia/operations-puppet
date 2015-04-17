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

    if os_version('ubuntu >= trusty') {
        include ::apache::mod::proxy_fcgi

        apache::mod_conf { 'mod_php5':
            ensure => absent,
        }

        # HHVM catchall, and removal of mod_php
        apache::conf { 'hhvm_catchall':
            source   => 'puppet:///modules/mediawiki/apache/configs/hhvm_catchall.conf',
            priority => 50,
        }

        # Mark static assets as coming from an HHVM appserver as well. Needed for Varnish
        apache::conf { 'mark_engine':
            source   => 'puppet:///modules/mediawiki/apache/configs/hhvm_mark_engine.conf',
            priority => 49,
        }

        # Add headers lost by mod_proxy_fastcgi
        apache::conf { 'fcgi_headers':
            source   => 'puppet:///modules/mediawiki/apache/configs/fcgi_headers.conf',
            priority => 0,
        }


    } else {
        include ::apache::mod::php5
    }

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
}
