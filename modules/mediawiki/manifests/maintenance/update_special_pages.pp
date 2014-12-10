
class mediawiki::maintenance::update_special_pages( $ensure = present ) {
    cron { 'update_special_pages':
        ensure   => $ensure,
        command  => 'flock -n /var/lock/update-special-pages /usr/local/bin/update-special-pages > /var/log/mediawiki/updateSpecialPages.log 2>&1',
        user     => $::mediawiki::users::web,
        monthday => '*/3',
        hour     => 5,
        minute   => 0,
    }

    file { '/usr/local/bin/update-special-pages':
        ensure => $ensure,
        source => 'puppet:///modules/mediawiki/maintenance/update-special-pages',
        owner  => $::mediawiki::users::web,
        group  => 'wikidev',
        mode   => '0755',
    }
}

