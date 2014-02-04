#Class for default sudoers file
class sudo::default {

    file { '/etc/sudoers':
        owner  => 'root',
        group  => 'root',
        mode   => '0440',
        source => 'puppet:///modules/sudo/sudoers.default',
    }

}

