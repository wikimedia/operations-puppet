class openstack::neutron::rabbit(
    $password,
    $username,
    ) {

    rabbitmq::user{"${username}-rabbituser":
        username => $username,
        password => $password,
    }
}
