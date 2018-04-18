# server hosting (an archive of) Parsoid releases
# https://releases.wikimedia.org/parsoid/
class profile::releases::parsoid {

    file { '/srv/org/wikimedia/releases/parsoid':
        ensure => 'directory',
        owner  => 'releasers-parsoid',
        group  => 'releasers-parsoid',
    }

}
