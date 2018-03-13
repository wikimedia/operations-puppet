class openstack::neutron::rabbit(
    $password,
    $username='neutron',
    ) {

    rabbitmq::user{"${username}-rabbituser":
        username => $username,
        password => $password,
    }
}
