# == Class postgresql::ganglia
# This installs a Ganglia plugin for postgresql
#
class postgresql::ganglia($ensure='present') {
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
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => "puppet:///modules/${module_name}/ganglia/postgresql.pyconf",
        notify => Service['gmond'],
    }
}
