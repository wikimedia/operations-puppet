# Setup rabbmitmq users where rabbit keeps an internal database
# At the moment, this does not attempt to alter existing passwords
# or permissions where the user already exists

# [*username]
#  string for user
# [*password]
#  string for pass
# [*ensure]
#  present or absent to setup or remove
# [*permissions]
#  rabbitmq style perms string
# [*adminstrator]
#  set rabbitmq management style admin tag
#  https://www.rabbitmq.com/management.html

define rabbitmq::user(
    $username,
    $password,
    $ensure='present',
    $permissions='".*" ".*" ".*"',
    $administrator=false,
    ) {

    if ($ensure == 'present') {
        exec {'rabbit_user_create':
            command => "/usr/sbin/rabbitmqctl add_user ${username} ${password}",
            unless  => "/usr/sbin/rabbitmqctl list_users | grep --quiet ${username}",
            notify  => Exec['rabbit_user_setup_perms'],
        }

        exec {'rabbit_user_setup_perms':
            command     => "/usr/sbin/rabbitmqctl set_permissions ${username} ${permissions}",
            refreshonly => true,
        }

        if ($administrator) {
            exec {"rabbit_user_{username}_adminstrator_tag":
                command     => "/usr/sbin/rabbitmqctl set_user_tags ${username} administrator",
                subscribe   => Exec['rabbit_user_setup_perms'],
                refreshonly => true,
            }
        }
    }

    if ($ensure == 'absent') {
        exec {'rabbit_user_removal':
            command => "/usr/sbin/rabbitmqctl delete_user ${username}",
            onlyif  => "/usr/sbin/rabbitmqctl list_users | grep --quiet ${username}",
        }
    }
}
