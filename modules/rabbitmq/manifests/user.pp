class rabbitmq::user(
    $ensure='present',
    $username,
    $password,
    $permissions='".*" ".*" ".*"',
    ), {

    if ($ensure == 'present') {
        exec {'rabbit_user_create':
            command => "rabbitmqctl add_user ${user} ${password}",
            path    => ['/usr/sbin/'],
            unless  => "rabbitmqctl list_users | grep --quiet ${USER}",
            notify  => Exec['rabbit_user_setup_perms'],
        }

        exec {'rabbit_user_setup_perms':
            command     => "rabbitmqctl set_permissions ${permissions}",
            path        => ['/usr/sbin/'],
            refreshonly => true,
        }
    }

    if ($ensure == 'absent') {
        exec {'rabbit_user_removal':
            command => "rabbitmqctl delete_user ${user}",
            onlyif  => "rabbitmqctl list_users | grep --quiet ${USER}",
        }
    }
}
