class role::wmcs::openstack::labtest::control {
    include profile::openstack::labtest::cloudrepo
    include profile::openstack::labtest::observerenv
    include profile::openstack::labtest::rabbitmq
}
