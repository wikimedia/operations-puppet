# = Class; graphite::labs::archiver
#
# Sets up a cron job that clears metrics from killed instances every
# hour
class graphite::labs::archiver {
    file { '/usr/local/bin/archive-instances':
        source => 'puppet:///modules/graphite/archive-instances',
        owner  => '_graphite',
        group  => '_graphite',
        mode   => '0700',
    }

    cron { 'archive-deleted-instances':
        command => '/usr/local/bin/archive-instances',
        user    => '_graphite',
        ensure  => present,
        minute  => 0,
        require => File['/usr/local/bin/archive-instances'],
    }
}
