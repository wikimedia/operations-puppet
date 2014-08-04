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

    if ubuntu_version('>= trusty') {
        include ::apache::mod::proxy_fcgi
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

    apache::mod_files { 'autoindex':
        ensure        => present,
        config_source => 'puppet:///modules/mediawiki/apache/modules/autoindex.conf'
    }

    apache::mod_files { 'expires':
        ensure        => present,
        config_source => 'puppet:///modules/mediawiki/apache/modules/expires.conf'
    }

    apache::mod_files { 'mime':
        ensure        => present,
        config_source => 'puppet:///modules/mediawiki/apache/modules/mime.conf'
    }

    apache::mod_files { 'setenvif':
        ensure        => present,
        config_source => 'puppet:///modules/mediawiki/apache/modules/setenvif.conf'
    }

    # TODO: remove this? It's not used anywhere AFAICT
    apache::mod_files { 'userdir':
        ensure        => present,
        config_source => 'puppet:///modules/mediawiki/apache/modules/userdir.conf'
    }
}
