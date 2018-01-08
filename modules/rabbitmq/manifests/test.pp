class rabbitmq::test {

    class {'::rabbitmq':}

    class {'::rabbitmq::cleanup':
        password => 'asdf',
        enabled  => true,
        username => 'drainqueue',
    }
}
