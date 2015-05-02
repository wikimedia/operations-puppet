class role::labs::mesos {
    include misc::labsdebrepo
}

class role::labs::mesos::master {

    include role::labs::mesos

    # Host zookeeper on itself
    include role::analytics::zookeeper::server

    include mesos::master
}