class openstack::neutron::rabbit(
    String[1] $username,
    String[1] $password,
) {
    rabbitmq::user { $username:
        password => $password,
    }
}
