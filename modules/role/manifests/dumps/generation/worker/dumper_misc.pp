class role::dumps::generation::worker::dumper_misc {
    include standard
    include ::profile::base::firewall

    include profile::dumps::generation::worker::common
    include profile::dumps::generation::worker::dumper
    include profile::dumps::generation::worker::cronrunner
    include profile::dumps::generation::worker::monitor

    system::role { 'snapshot::dumper_misc':
        description => 'dumper of XML/SQL wiki content, misc dumps, monitor',
    }
}
