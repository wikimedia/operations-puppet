# rsync sanitized data that has been readied for public consumption to a
# web server.
class statistics::public_datasets {
    file { '/a/public-datasets':
        ensure => 'directory',
        owner  => 'root',
        group  => 'www-data',
        mode   => '0640',
    }

    # symlink /var/www/public-datasets to /a/public-datasets
    file { '/var/www/public-datasets':
        ensure => 'link',
        target => '/a/public-datasets',
        owner  => 'root',
        group  => 'www-data',
        mode   => '0640',
    }

    # rsync from stat1:/a/public-datasets to /a/public-datasets
    cron { 'rsync public datasets':
        command => '/usr/bin/rsync -rt --delete stat1.wikimedia.org::a/public-datasets/* /a/public-datasets/',
        require => File['/a/public-datasets'],
        user    => 'root',
        minute  => '*/30',
    }
}


