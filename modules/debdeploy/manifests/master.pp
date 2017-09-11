# sets up a debdeploy master
class debdeploy::master {

    require_package('debdeploy-server')

    file { '/etc/debdeploy.conf':
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            content => template('debdeploy/debdeploy.erb');
    }
}
