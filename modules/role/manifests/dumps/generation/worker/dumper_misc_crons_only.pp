class role::dumps::generation::worker::dumper_misc_crons_only {
    include ::profile::standard
    include ::profile::base::firewall

    include profile::dumps::generation::worker::common
    include profile::dumps::generation::worker::cronrunner

    system::role { 'dumps::generation::worker::dumper_misc_crons':
        description => 'dumper of misc dumps (such as wikidata weeklies, cirrussearch)',
    }
}
