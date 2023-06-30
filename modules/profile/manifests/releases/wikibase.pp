# https://releases.wikimedia.org/wikibase
class profile::releases::wikibase {
    file { '/srv/org/wikimedia/releases/wikibase':
        ensure => directory,
        owner  => 'root',
        group  => 'releasers-wikibase',
        mode   => '2775',
    }
}
