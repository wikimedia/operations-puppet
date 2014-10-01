# == Class ocg::ganglia::module
# Includes the ocg.py ganglia module
# include this class on your OCG node.
#
class ocg::ganglia::module (
        $tmp_filesystem = '/mnt/tmpfs',
        $data_filesystem = '/srv',
    ) {
    file { '/usr/lib/ganglia/python_modules/ocg.py':
        source => 'puppet:///modules/ocg/ganglia/ocg.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/etc/ganglia/conf.d/ocg.pyconf':
        content => template('ocg/ganglia/ocg.pyconf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }
}
