class sudo {
    package { 'sudo':
        ensure => installed,
    }

    class { 'sudo::sudoersfile':
        package => 'sudo',
    }
}
