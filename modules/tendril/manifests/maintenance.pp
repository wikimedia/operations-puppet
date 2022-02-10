# This class sets up the regular jobs needed for the correct execution
# of the tendril web interface and database
# It does not require being run on the same server than the web
# or the database, but it requires having mysql access

class tendril::maintenance (
    $tendril_host,
    $tendril_user,
    $tendril_password,
    $tendril_db = 'tendril',
    $tendril_port = 3306,
    $wd_user = undef,
    $wd_password = undef,
    $ensure = present,
){

    ensure_packages(['libdbi-perl', 'libdbd-mysql-perl'])

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
        ensure => absent,
        owner  => 'tendril',
        group  => 'tendril',
        mode   => '0750',
        source => 'puppet:///modules/tendril/tendril-cron-5m.pl',
    }

    file { '/usr/local/bin/tendril-queries.pl':
        ensure => absent,
        owner  => 'tendril',
        group  => 'tendril',
        mode   => '0750',
        source => 'puppet:///modules/tendril/tendril-queries.pl',
    }

    file { '/etc/mysql/tendril.cnf':
        ensure  => absent,
        owner   => 'tendril',
        group   => 'tendril',
        mode    => '0640',
        content => template('tendril/tendril.cnf.erb'),
    }
}
