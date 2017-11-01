class role::dumps::generation::worker::dumper {
    include standard
    include ::base::firewall

    include profile::dumps::generation::worker::common
    include profile::dumps::generation::worker::dumper

    system::role { 'snapshot::dumper':
        description => 'dumper of XML/SQL wiki content',
    }
}
