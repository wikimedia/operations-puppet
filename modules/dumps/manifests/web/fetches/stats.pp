class dumps::web::fetches::stats(
    $src = undef,
    $miscdatasetsdir = undef,
    $user = undef,
) {
    # Each of these jobs have a readme.html file rendered by  dumps::web::html.
    # We need to make sure the rsync --delete does not delete these files
    # which are put in place on the local destination host by puppet.
    Dumps::Web::Fetches::Job {
        exclude => 'readme.html'
    }

    # Copies over the mediacounts files from an rsyncable location.
    dumps::web::fetches::job { 'mediacounts':
        source      => "${src}/mediacounts",
        destination => "${miscdatasetsdir}/mediacounts",
        minute      => '41',
        user        => $user,
    }

    # Copies over files with pageview statistics per page and project,
    # using the current definition of pageviews, from an rsyncable location.
    dumps::web::fetches::job { 'pageview':
        source      => "${src}/{pageview,projectview}/legacy/hourly",
        destination => "${miscdatasetsdir}/pageviews",
        minute      => '51',
        user        => $user,
    }

    # Copies over files with unique devices statistics per project,
    # using the last access cookie method, from an rsyncable location.
    dumps::web::fetches::job { 'unique_devices':
        source      => "${src}/unique_devices",
        destination => "${miscdatasetsdir}/unique_devices",
        minute      => '31',
        user        => $user,
    }

    # Copies over clickstream files from an rsyncable location.
    dumps::web::fetches::job { 'clickstream':
        source      => "${src}/clickstream",
        destination => "${miscdatasetsdir}/clickstream",
        hour        => '4',
        user        => $user,
    }

    # Copies over mediawiki history dumps from an rsyncable location.
    dumps::web::fetches::job { 'mediawiki_history_dumps':
        ensure      => absent,
        source      => "${src}/mediawiki/history",
        destination => "${miscdatasetsdir}/mediawiki_history",
        hour        => '5',
        user        => $user,
    }
}
