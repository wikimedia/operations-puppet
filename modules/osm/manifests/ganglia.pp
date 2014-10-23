# == Class osm::ganglia
# This installs a Ganglia plugin for osm
#
class osm::ganglia(
                refresh_rate = 15,
                $ensure = 'present') {
    file { '/usr/lib/ganglia/python_modules/osm.py':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => "puppet:///modules/${module_name}/ganglia/osm.py",
        notify => Service['gmond'],
    }

    file { '/etc/ganglia/conf.d/osm.pyconf':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('osm/ganglia/osm.pyconf.erb'),
        notify  => Service['gmond'],
    }
}
