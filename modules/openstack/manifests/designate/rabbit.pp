# SPDX-License-Identifier: Apache-2.0

class openstack::designate::rabbit(
    String[1] $username,
    String[1] $password,
) {
    rabbitmq::user { $username:
        password => $password,
    }
}
