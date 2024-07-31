# SPDX-License-Identifier: Apache-2.0
class openstack::trove::rabbit(
    String[1] $username,
    String[1] $password,
    String[1] $guest_username,
    String[1] $guest_password,
) {
    rabbitmq::user { $username:
        password => $password,
    }

    # TODO: reduce the permissions this user has
    rabbitmq::user { $guest_username:
        password => $guest_password,
    }
}
