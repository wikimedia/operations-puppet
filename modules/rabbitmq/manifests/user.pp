# SPDX-License-Identifier: Apache-2.0
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
    String[1]      $password,
    String[1]      $username      = $title,
    Wmflib::Ensure $ensure        = 'present',
    String[1]      $permissions   = '".*" ".*" ".*"',
    Boolean        $administrator = false,
) {
    if $ensure == 'present' {
        exec { "rabbit_${username}_create":
            command => "/usr/sbin/rabbitmqctl add_user ${username} ${password}",
            unless  => "/usr/sbin/rabbitmqctl list_users | grep --quiet ${username}",
            require => Service['rabbitmq-server'],
            notify  => Exec["rabbit_${username}_setup_perms"],
        }

        exec { "rabbit_${username}_setup_perms":
            command     => "/usr/sbin/rabbitmqctl set_permissions ${username} ${permissions}",
            refreshonly => true,
            require     => Service['rabbitmq-server'],
        }

        if $administrator {
            exec { "rabbit_user_${username}_adminstrator_tag":
                command     => "/usr/sbin/rabbitmqctl set_user_tags ${username} administrator",
                subscribe   => Exec["rabbit_${username}_setup_perms"],
                require     => Service['rabbitmq-server'],
                refreshonly => true,
            }
        }
    } else {
        exec { "${username}-rabbit_user_removal":
            command => "/usr/sbin/rabbitmqctl delete_user ${username}",
            onlyif  => "/usr/sbin/rabbitmqctl list_users | grep --quiet ${username}",
            require => Service['rabbitmq-server'],
        }
    }
}
