# https://releases.wikimedia.org/blubber
class profile::releases::blubber {
    file { '/srv/org/wikimedia/releases/blubber':
        ensure => directory,
        owner  => 'root',
        group  => 'releasers-blubber',
        mode   => '2775',
    }
}
