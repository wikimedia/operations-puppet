# == Class ocg::ganglia
# Includes the ocg.py ganglia module
# include this class on your OCG node.
#
class ocg::ganglia (
    $tmp_filesystem  = $::ocg::temp_dir,
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
