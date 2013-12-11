# == Class: ocg_collection
#
# Node service for the MediaWiki Collection extension providing article
# rendering.
#
# Collections, or books, or individual articles are submitted
# to the service as jobs which are stored in redis. Any node may accept
# a job on behalf of the cluster (providing all nodes share a redis
# instance.) Similarly, any node is then able to pick up the job when it
# is free to work.
#

class ocg_collection (
    $host_name = $::fqdn,
    $redis_host = 'localhost',
    $redis_port = 6379,
    $redis_password = '',
    $temp_dir = '/tmp/ocg_collection'
) {
    deployment::target { 'ocg-collection': }

    group { 'ocg_collection':
        ensure => present,
    }

    user { 'ocg_collection':
        ensure     => present,
        gid        => 'ocg',
        shell      => '/bin/false',
        home       => '/srv/deployment/ocg_collection',
        managehome => false,
        system     => true,
    }

    package {
        [
            'nodejs',
            'texlive-xetex',
            'texlive-latex-recommended',
            'texlive-latex-extra',
            'texlive-fonts-recommended',
            'texlive-lang-all',
            'latex-xcolor',
            'imagemagick',
            'librsvg2-bin',
            'zip',
            'unzip',
        ]: ensure => latest
    }

    file { "/etc/ocg-collection.js":
        ensure  => present,
        content => template('ocg_collection/mw-collection-ocg.erb'),
        notify  => Service['ocg-collection'],
    }

    file { '/etc/init/ocg-collection.conf':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        source  => 'puppet:///files/misc/ocg-collection.conf',
        notify  => Service['ocg-collection'],
    }

    file { $temp_dir:
        path    => $temp_dir,
        ensure  => directory,
        owner   => 'ocg_collection',
        group   => 'ocg_collection',
        mode    => '0664',
    }

    file { [ '/var/log/ocg_collection', '/var/log/ocg_collection/archive' ]:
        ensure  => directory,
        owner   => 'ocg_collection',
        group   => 'ocg_collection',
        mode    => '0664',
    }

    file { '/etc/logrotate.d/ocg_collection':
        source  => 'puppet:///modules/ocg_collection/logrotate',
        require => File['/var/log/ocg_collection/archive'],
        mode    => '0444',
    }
}
