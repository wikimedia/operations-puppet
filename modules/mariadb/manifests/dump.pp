
class mariadb::dump(
    $user,
    $pass,
    $folder  = '/srv/dump',
    $threads = 3,
    ) {

    package { [
        'pigz',
    ]:
        ensure => present,
    }

    file { "$folder":
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    file { '/usr/local/bin/dumps.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => template('mariadb/dumps.sh.erb'),
    }

    cron { 'mariadb_dump':
        ensure  => present,
        user    => 'root',
        minute  => 0,
        hour    => 1,
        weekday => 0,
        command => "/usr/local/bin/dumps.sh >${folder}/dumps-$(date +%Y%m%d).log 2>&1",
        require => File['/usr/local/bin/dumps.sh'],
    }

    cron { 'mariadb_dump_purge':
        ensure  => present,
        user    => 'root',
        minute  => 0,
        hour    => 0,
        weekday => 0,
        command => "find $folder/* -mtime +15 -exec rm {} \\;",
    }
}