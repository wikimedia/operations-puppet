# https://releases.wikimedia.org/mwcli
class profile::releases::mwcli {
    file { '/srv/org/wikimedia/releases/mwcli':
        ensure => directory,
        owner  => 'root',
        group  => 'releasers-mwcli',
        mode   => '2775',
    }
}
