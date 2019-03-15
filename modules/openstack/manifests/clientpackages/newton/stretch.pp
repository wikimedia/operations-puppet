class openstack::clientpackages::newton::stretch(
) {
    # no special repo is configured, yet?

    # TODO: What is this doing here?
    package { 'mariadb-client-10.1':
        ensure => 'present',
    }
}
