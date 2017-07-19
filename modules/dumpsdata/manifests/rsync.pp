class dataset::cron::rsync() {
    include ::dataset::common

    file { '/usr/local/bin/rsync_completed_dumpjobs.py':
        ensure => 'present',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        path   => '/usr/local/bin/rsync_completed_dumpjobs.py',
        source => 'puppet:///modules/dumpsdata/rsync_completed_dumpjobs.py',
    }

    cron { 'rsync-dumps':
        ensure  => present,
        # filter out error messages about vanishing files, we don't want email for that
        command => '/usr/bin/python /usr/local/bin/rsync-completed_dumpjobs.py 2>&1 | grep -v "vanished" ',
        user    => 'root',
        minute  => '10',
        hour    => '*',
        require => File['/usr/local/bin/rsync-completed_dumpjobs.py'],
    }
}
