class openstack::clientpackages::newton::stretch(
) {
    # no special repo is configured, yet?

    package{ 'mariadb-client-10.1':
        ensure => 'present',
    }
}
