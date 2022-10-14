# SPDX-License-Identifier: Apache-2.0

class openstack::magnum::rabbit(
    String[1] $username,
    String[1] $password,
) {
    rabbitmq::user { $username:
        password => $password,
    }
}
