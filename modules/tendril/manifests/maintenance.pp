# This class sets up the cron jobs needed for the correct execution
# of the tendril web interface and database
# It does not require being run on the same server than the web
# or the database, but it requires having mysql access

class tendril::maintenance (
    $tendril_host,
    $tendril_user,
    $tendril_password,
    $tendril_port = 3306,
    $watchdog_user = NONE,
    $watchdog_password = NONE,
){

    if ($watchdog_user == NONE) {
        $watchdog_user = $tendril_user
    }
    if ($watchdog_password == NONE) {
        $watchdog_password = $tendril_password
    }

    group { 'tendril':
        ensure => present,
        name   => 'tendril',
    }

    user { 'tendril':
        ensure  => present,
        gid     => 'tendril',
        shell   => '/bin/false',
        home    => '/tmp',
        system  => true,
        require => Group['tendril'],
    }

    file { '/usr/local/bin/tendril-cron-5m.pl':
        ensure => file,
        owner  => 'tendril',
        group  => 'tendril',
        mode   => '0750',
        source => 'puppet:///modules/tendril/tendril-cron-5m.pl',
    }

    file { '/var/log/tendril-cron-5m.log':
        ensure => present,
        owner  => 'tendril',
        group  => 'tendril',
        mode   => '0640',
    }

    file { '/usr/local/bin/tendril-queries.pl':
        ensure => file,
        owner  => 'tendril',
        group  => 'tendril',
        mode   => '0750',
        source => 'puppet:///modules/tendril/tendril-queries.pl',
    }

    file { '/var/log/tendril-queries.log':
        ensure => present,
        owner  => 'tendril',
        group  => 'tendril',
        mode   => '0640',
    }

    file { '/var/log/tendril-queries.err':
        ensure => present,
        owner  => 'tendril',
        group  => 'tendril',
        mode   => '0640',
    }

    file { '/etc/mysql/tendril.cfg':
        ensure  => file,
        owner   => 'tendril',
        group   => 'tendril',
        mode    => '0640',
        content => template('tendril/tendril.cfg.erb'),
    }

    cron { 'tendril-cron-5m':
        ensure  => present,
        user    => 'tendril',
        minute  => '*/5',
        command => '/usr/local/bin/tendril-cron-5m.pl \
/etc/mysql/tendril.cnf > /var/log/tendril-cron-5m.log 2> \
/var/log/tendril-cron-5m.err',
        require => [
            File['/usr/local/bin/tendril-cron-5m.pl'],
            File['/var/log/tendril-cron-5m.log'],
            File['/var/log/tendril-cron-5m.err'],
        ]
    }

    cron { 'tendril-queries':
        ensure  => present,
        user    => 'tendril',
        minute  => '*/5',
        command => '/usr/local/bin/tendril-queries.pl \
/etc/mysql/tendril.cnf > /var/log/tendril-queries.log 2> \
/var/log/tendril-queries.err',
        require => [
            File['/usr/local/bin/tendril-queries.pl'],
            File['/var/log/tendril-queries.log'],
            File['/var/log/tendril-queries.err'],
            File['/etc/mysql/tendril.cfg'],
        ]
    }
}
