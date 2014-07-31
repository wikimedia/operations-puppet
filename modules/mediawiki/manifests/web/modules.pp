class mediawiki::web::modules {
    include ::mediawiki::web

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

        # This will be useful once we switch to mpm worker. Please keep it.
        file { '/etc/apache2/mods-available/mpm_worker.conf':
            ensure  => present,
            content  => template('mediawiki/apache/modules/mpm_worker.conf.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            before  => Class['::apache::mpm'],
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

    file { '/etc/apache2/mods-available/mpm_prefork.conf':
        ensure  => present,
        content  => template('mediawiki/apache/modules/mpm_prefork.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['apache2'],
        before  => Class['::apache::mpm'],
    }

    # As we already have apache::mpm declared, the prefork conf file
    # wouldn't be loaded or linked, so we ensure that manually.
    file { '/etc/apache2/mods-enabled/mpm_prefork.conf':
        ensure => link,
        target => '/etc/apache2/mods-available/mpm_prefork.conf',
        before => Class['::apache::mpm'],
    }

    file { '/etc/apache2/mods-available/expires.conf':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/apache/modules/expires.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Class['::apache::mod::expires'],
    }

    file { '/etc/apache2/mods-available/autoindex.conf':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/apache/modules/autoindex.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Class['::apache::mod::autoindex'],
    }


    file { '/etc/apache2/mods-available/setenvif.conf':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/apache/modules/setenvif.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['apache2'],
    }

    file { '/etc/apache2/mods-available/mime.conf':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/apache/modules/mime.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['apache2'],
    }

    # TODO: remove this? It's not used anywhere AFAICT
    file { '/etc/apache2/mods-available/userdir.conf':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/apache/modules/userdir.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
