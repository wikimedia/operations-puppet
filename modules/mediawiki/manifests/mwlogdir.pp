# log directory for mediawiki maintenance logs
class mediawiki::mwlogdir {

    file { '/var/log/mediawiki':
        ensure => directory,
        owner  => 'root',
        group  => 'wikidev',
        mode   => '0555',
    }

}

