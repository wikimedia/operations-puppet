# == Class authdns::ganglia
# This installs a Ganglia plugin for gdnsd
#
class authdns::ganglia {
    Class['authdns'] -> Class['authdns::ganglia']

    file { '/usr/lib/ganglia/python_modules/gdnsd.py':
        source => "puppet:///modules/${module_name}/ganglia/ganglia_gdnsd.py",
    }

    file { '/etc/ganglia/conf.d/gdnsd.pyconf':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => "puppet:///modules/${module_name}/ganglia/gdnsd.pyconf",
        notify => Service['gmond'],
    }
}
