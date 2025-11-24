# https://releases.wikimedia.org/blubber
class profile::releases::blubber {
    file { '/srv/org/wikimedia/releases/blubber':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '2775',
    }
}
