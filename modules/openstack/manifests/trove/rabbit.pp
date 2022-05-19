# SPDX-License-Identifier: Apache-2.0
class openstack::trove::rabbit(
    String[1] $guest_username,
    String[1] $guest_password,
) {
    # TODO: reduce the permissions this user has
    rabbitmq::user { $guest_username:
        password => $guest_password,
    }
}
