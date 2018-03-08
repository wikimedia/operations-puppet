class openstack::nova::rabbit(
    $username,
    $password,
 {
    require rabbitmq
    # admin is needed for queue cleanup
    rabbitmq::user{"${username}-rabbituser":
        username      => $username,
        password      => $password,
    }
}
