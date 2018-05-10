class role::dumps::generation::worker::dumper_misc_crons_only {
    include standard
    include ::profile::base::firewall

    include profile::dumps::generation::worker::common
    include profile::dumps::generation::worker::cronrunner

    system::role { 'snapshot::dumper_misc':
        description => 'dumper of XML/SQL wiki content, misc dumps, monitor',
    }
}
