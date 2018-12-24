class role::dumps::generation::worker::dumper_misc_crons_only {
    include standard
    include ::profile::base::firewall

    include profile::dumps::generation::worker::common
    include profile::dumps::generation::worker::cronrunner

    system::role { 'dumps::generation::worker::dumper_misc_crons_only':
        description => 'producer of misc dumps such as wikidata weeklies',
    }
}
