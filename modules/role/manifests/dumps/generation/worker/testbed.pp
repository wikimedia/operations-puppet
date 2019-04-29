class role::dumps::generation::worker::testbed {
    include ::profile::standard
    include ::profile::base::firewall

    include profile::dumps::generation::worker::common
    include profile::dumps::generation::worker::crontester

    system::role { 'dumps::generation::worker::testbed':
        description => 'testbed for dumps of XML/SQL wiki content',
    }
}
