# == Class postgresql::ganglia
# This installs a Ganglia plugin for postgresql
#
class postgresql::ganglia(
                    $pgstats_user,
                    $pgstats_pass,
                    $pgstats_db = 'template1',
                    $pgstats_host = '127.0.0.1',
                    $pgstats_port = '5432',
                    $pgstats_refresh_rate = 60,
                    $ensure='present') {
    Class['postgresql::server'] -> Class['postgresql::ganglia']

    package { 'python-psycopg2':
        ensure => $ensure,
    }

    file { '/usr/lib/ganglia/python_modules/postgresql.py':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => "puppet:///modules/${module_name}/ganglia/postgresql.py",
        notify => Service['gmond'],
    }

    file { '/etc/ganglia/conf.d/postgresql.pyconf':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('postgresql/ganglia/postgresql.pyconf.erb'),
        notify  => Service['gmond'],
    }
}
