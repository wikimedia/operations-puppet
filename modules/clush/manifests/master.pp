class clush::master(
    $username,
    $ensure = present,
) {

    file { '/root/.ssh':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0700',
    }

    file { "/root/.ssh/${username}":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => File['/root/.ssh'],
    }

    $config = {
        'Main' => {
            'fanout'          => 16,
            'connect_timeout' => 15,
            'command_timeout' => 0,
            'color'           => 'auto',
            'fd_max'          => '16384',
            'history_size'    => 1024,
            'node_count'      => 'yes',
            'verbosity'       => 1,
            'ssh_user'        => $username,
            'ssh_options'     => "-i /root/.ssh/${username} -oStrictHostKeyChecking=no",
        }
    }

    file { '/etc/clustershell/clush.ini':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => ini($config),
    }
}
