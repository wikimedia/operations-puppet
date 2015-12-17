# This class sets up the cron jobs needed for the correct execution
# of the tendril web interface and database
# It does not require being run on the same server than the web
# or the database, but it requires having mysql access

class tendril::maintenance (
    $ensure = present,
    $tendril_host,
    $tendril_user,
    $tendril_password,
    $tendril_db = 'tendril',
    $tendril_port = 3306,
    $wd_user = undef,
    $wd_password = undef,
){

    # We want to control if cron is running, not if the scripts are installed.
    Cron {
        ensure => $ensure
    }

    File {
        ensure => present
    }

    $watchdog_user = $wd_user ? {
        undef   => $tendril_user,
        default => $wd_user,
    }
    $watchdog_password = $wd_password ? {
        undef   => $tendril_password,
        default => $wd_password,
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
        owner  => 'tendril',
        group  => 'tendril',
        mode   => '0750',
        source => 'puppet:///modules/tendril/tendril-cron-5m.pl',
    }

    file { '/var/log/tendril-cron-5m.log':
        owner => 'tendril',
        group => 'tendril',
        mode  => '0640',
    }

    file { '/var/log/tendril-cron-5m.err':
        owner => 'tendril',
        group => 'tendril',
        mode  => '0640',
    }

    file { '/usr/local/bin/tendril-queries.pl':
        owner  => 'tendril',
        group  => 'tendril',
        mode   => '0750',
        source => 'puppet:///modules/tendril/tendril-queries.pl',
    }

    file { '/var/log/tendril-queries.log':
        owner => 'tendril',
        group => 'tendril',
        mode  => '0640',
    }

    file { '/var/log/tendril-queries.err':
        owner => 'tendril',
        group => 'tendril',
        mode  => '0640',
    }

    file { '/etc/mysql/tendril.cnf':
        owner   => 'tendril',
        group   => 'tendril',
        mode    => '0640',
        content => template('tendril/tendril.cnf.erb'),
    }

    cron { 'tendril-cron-5m':
        user    => 'tendril',
        command => '/usr/local/bin/tendril-cron-5m.pl /etc/mysql/tendril.cnf > /var/log/tendril-cron-5m.log 2> /var/log/tendril-cron-5m.err',
        minute  => '*/5',
        require => [
            File['/usr/local/bin/tendril-cron-5m.pl'],
            File['/var/log/tendril-cron-5m.log'],
            File['/var/log/tendril-cron-5m.err'],
        ]
    }

    cron { 'tendril-queries':
        user    => 'tendril',
        command => '/usr/local/bin/tendril-queries.pl /etc/mysql/tendril.cnf > /var/log/tendril-queries.log 2> /var/log/tendril-queries.err',
        minute  => '*/5',
        require => [
            File['/usr/local/bin/tendril-queries.pl'],
            File['/var/log/tendril-queries.log'],
            File['/var/log/tendril-queries.err'],
            File['/etc/mysql/tendril.cnf'],
        ]
    }
}
