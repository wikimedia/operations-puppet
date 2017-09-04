class dumps::otherdumps::wikidata::json(
    $user   = undef,
) {
    # nope, requires the user param. ugh
    include ::dumps::otherdumps::wikidata::common

    file { '/usr/local/bin/dumpwikidatajson.sh':
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/dumps/otherdumps/wikidata/dumpwikidatajson.sh',
        require => Class['dumpscrons::wikidata::common'],
    }
}
