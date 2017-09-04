class dumps::otherdumps::weekly::globalblocks(
    $user = undef,
) {
    file { '/usr/local/bin/dump-global-blocks.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/otherdumps/weeklies/dump-global-blocks.sh',
    }
}
