class openstack::nova::rabbit(
    $username,
    $password,
    ) {

    rabbitmq::user{"${username}-rabbituser":
        username => $username,
        password => $password,
    }
}
