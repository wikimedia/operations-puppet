class role::dumps::generation::worker::testbed {
    include standard
    include ::profile::base::firewall

    include profile::dumps::generation::worker::common

    system::role { 'dumps::generation::worker::testbed':
        description => 'testbed for dumps of XML/SQL wiki content',
    }
}
