class mediawiki::web::modules (
    $use_hhvm = $::mediawiki::web::use_hhvm,
    $max_req_workers = $::mediawiki::web::max_req_workers
)
{
    include apache::mod::autoindex
    include apache::mod::dir
    include apache::mod::setenvif
    include apache::mod::authz_host
    include apache::mod::expires
    include apache::mod::rewrite
    include apache::mod::headers
    include apache::mod::alias
    include apache::mod::mime
    include apache::mod::status

    if $use_hhvm {
        include apache::mod::mpm_worker
        include apache::mod::proxy_fcgi

        file { '/etc/apache2/mods-available/mpm_worker.conf':
            ensure  => present,
            content  => template('/mediawiki/apache/modules/mpm_worker.conf.erb'),
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            before  => Class['apache::mod::mpm_worker'],
        }

    } else {
        include apache::mod::php5
    }

    file { '/etc/apache2/mods-available/expires.conf':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/apache/modules/expires.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Class['apache::mod::expires'],
    }

    file { '/etc/apache2/mods-available/autoindex.conf':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/apache/modules/autoindex.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Class['apache::mod::autoindex'],
    }


    file { '/etc/apache2/mods-available/setenvif.conf':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/apache/modules/setenvif.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['apache']
    }

    file { '/etc/apache2/mods-available/mime.conf':
        ensure  => present,
        source  => 'puppet:///modules/mediawiki/apache/modules/mime.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['apache']
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
