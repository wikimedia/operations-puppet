class dumps::otherdumps::weekly::contentxlation(
    $user = undef,
) {
    file { '/usr/local/bin/dumpcontentxlation.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/otherdumps/weeklies/dumpcontentxlation.sh',
    }
}
