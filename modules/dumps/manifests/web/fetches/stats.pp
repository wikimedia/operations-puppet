class dumps::web::fetches::stats(
    $src = undef,
    $src_hdfs = undef,
    $miscdatasetsdir = undef,
    $user = undef,
    $use_kerberos = false,
) {
    # Each of these jobs have a readme.html file rendered by  dumps::web::html.
    # We need to make sure the rsync --delete does not delete these files
    # which are put in place on the local destination host by puppet.
    Dumps::Web::Fetches::Job {
        exclude => 'readme.html'
    }
    Dumps::Web::Fetches::Analytics::Job {
        exclude => 'readme.html'
    }

    # Copies over the mediacounts files from an rsyncable location.
    dumps::web::fetches::job { 'mediacounts':
        ensure      => absent,
        source      => "${src}/mediacounts",
        destination => "${miscdatasetsdir}/mediacounts",
        minute      => '41',
        user        => $user,
    }

    dumps::web::fetches::analytics::job { 'mediacounts':
        source       => "${src}/mediacounts",
        destination  => "${miscdatasetsdir}/mediacounts",
        interval     => '*-*-* *:41:00',
        user         => $user,
        use_kerberos => $use_kerberos,
    }

    # Copies over files with pageview statistics per page and project,
    # using the current definition of pageviews, from an rsyncable location.
    dumps::web::fetches::job { 'pageview':
        ensure      => absent,
        source      => "${src}/{pageview,projectview}/legacy/hourly",
        destination => "${miscdatasetsdir}/pageviews",
        minute      => '51',
        user        => $user,
    }

    dumps::web::fetches::analytics::job { 'pageview':
        source       => "${src}/{pageview,projectview}/legacy/hourly",
        destination  => "${miscdatasetsdir}/pageviews",
        interval     => '*-*-* *:51:00',
        user         => $user,
        use_kerberos => $use_kerberos,
    }

    # Copies over files with unique devices statistics per project,
    # using the last access cookie method, from an rsyncable location.
    dumps::web::fetches::job { 'unique_devices':
        ensure      => absent,
        source      => "${src}/unique_devices",
        destination => "${miscdatasetsdir}/unique_devices",
        minute      => '31',
        user        => $user,
    }

    dumps::web::fetches::analytics::job { 'unique_devices':
        source       => "${src}/unique_devices",
        destination  => "${miscdatasetsdir}/unique_devices",
        interval     => '*-*-* *:31:00',
        user         => $user,
        use_kerberos => $use_kerberos,
    }

    # Copies over clickstream files from an rsyncable location.
    dumps::web::fetches::job { 'clickstream':
        ensure      => absent,
        source      => "${src}/clickstream",
        destination => "${miscdatasetsdir}/clickstream",
        hour        => '4',
        user        => $user,
    }

    dumps::web::fetches::analytics::job { 'clickstream':
        source       => "${src}/clickstream",
        destination  => "${miscdatasetsdir}/clickstream",
        interval     => '*-*-* *:04:00',
        user         => $user,
        use_kerberos => $use_kerberos,
    }

    # Copies over mediawiki history dumps from an rsyncable location.
    dumps::web::fetches::job { 'mediawiki_history_dumps':
        ensure      => absent,
        source      => "${src}/mediawiki/history",
        destination => "${miscdatasetsdir}/mediawiki_history",
        hour        => '5',
        user        => $user,
    }

    # Copying only the last 2 dumps explicitely (--delete will take care of deleting old ones)
    dumps::web::fetches::analytics::job { 'mediawiki_history_dumps':
        source         => "${src_hdfs}/mediawiki/history/{\$(/bin/date --date=\"\$\$(/bin/date +%%Y-%%m-15) -1 month\" +\"%%Y-%%m\"),\$\$(/bin/date --date=\"\$\$(/bin/date +%%Y-%%m-15) -2 month\" +\"%%Y-%%m\")}",
        destination    => "${miscdatasetsdir}/mediawiki_history/",
        interval       => '*-*-* 05:00:00',
        user           => $user,
        use_kerberos   => $use_kerberos,
        use_hdfs_rsync => true,
    }

    # Copies over geoeditors dumps from an rsyncable location.
    dumps::web::fetches::job { 'geoeditors_dumps':
        source      => "${src}/geoeditors/public",
        destination => "${miscdatasetsdir}/geoeditors",
        hour        => '6',
        user        => $user,
    }
}
