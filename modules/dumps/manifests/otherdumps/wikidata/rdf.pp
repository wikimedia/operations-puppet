class dumps::otherdumps::wikidata::rdf(
    $user   = undef,
) {
    # nope needs 'user' param. ugh
    include ::dumpscrons::wikidata::common

    file { '/usr/local/bin/dumpwikidatardf.sh':
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/dumps/otherdumps/wikidata/dumpwikidatardf.sh',
        require => Class['dumps::otherdumps::wikidata::::common'],
    }
}
