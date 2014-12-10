class mediawiki::maintenance::update_special_pages( $ensure = present ) {
    cron { 'update_special_pages':
        ensure   => $ensure,
        command  => 'flock -n /var/lock/update-special-pages /usr/local/bin/foreachwiki updateSpecialPages.php > /var/log/mediawiki/updateSpecialPages.log 2>&1',
        user     => $::mediawiki::users::web,
        monthday => '*/3',
        hour     => 5,
        minute   => 0,
    }
}

