class dumps::web::fetches::stats(
    $src = undef,
    $miscdatasetsdir = undef,
    $user = undef,
) {
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
}
