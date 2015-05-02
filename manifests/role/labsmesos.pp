class role::labs::mesos {
    include misc::labsdebrepo
}

class role::labs::mesos::master {

    include role::labs::mesos

    # Host zookeeper on itself
    include zookeeper::server

    include mesos::master
}