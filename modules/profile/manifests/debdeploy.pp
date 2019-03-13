# Sets up a debdeploy server
class profile::debdeploy {

    require_package('debdeploy-server')

    file { '/etc/debdeploy.conf':
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/profile/debdeploy/debdeploy.conf',
    }
}
