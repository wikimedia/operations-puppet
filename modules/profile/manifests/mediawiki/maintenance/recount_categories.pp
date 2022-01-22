class profile::mediawiki::maintenance::recount_categories {
    profile::mediawiki::periodic_job { 'recount_categories':
        command  => '/usr/local/bin/foreachwiki recountCategories.php --mode all',
        interval => '*-*-01 04:00'

    }
}
