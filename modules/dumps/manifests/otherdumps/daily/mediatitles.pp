class dumps::otherdumps::daily::mediaperprojectlists(
    $user = undef,
) {
    file { '/usr/local/bin/create-media-per-project-lists.sh':
        ensure => 'present',
        path   => '/usr/local/bin/create-media-per-project-lists.sh',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/otherdumps/dailies/create-media-per-project-lists.sh',
    }
}
