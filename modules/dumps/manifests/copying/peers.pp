class dumps::copying::peers(
    $desthost = undef,
) {
    file { '/usr/local/bin/rsync_from_webserver.sh':
        ensure => 'present',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        path   => '/usr/local/bin/rsync_from_webserver.sh',
        source => 'puppet:///modules/dumps/copying/rsync_from_webserver.sh'
    }

    cron { 'rsync-dumps':
        ensure  => 'present',
        # filter out error messages about vanishing files, we don't want email for that
        command => "/bin/bash /usr/local/bin/rsync_from_webserver.sh --desthost ${desthost} 2>&1 | grep -v "vanished" ",
        user    => 'root',
        minute  => '0',
        hour    => '*/2',
        require => File['/usr/local/bin/rsync_from_webserver.sh'],
    }
}
