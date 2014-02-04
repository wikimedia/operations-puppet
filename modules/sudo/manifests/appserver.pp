# application servers sudoers file
class sudo::appserver {

    file { '/etc/sudoers.d/appserver':
        ensure => 'present',
        path   => '/etc/sudoers.d/appserver',
        owner  => 'root',
        group  => 'root',
        mode   => '0440',
        source => 'puppet:///modules/sudo/sudoers.appserver',
    }

}

