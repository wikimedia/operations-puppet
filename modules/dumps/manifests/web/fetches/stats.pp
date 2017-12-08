class dumps::web::fetches::stats(
    $src = undef,
    $otherdir = undef,
    $user = undef,
) {
    # Copies over the mediacounts files from an rsyncable location.
    dumps::web::fetches::job { 'mediacounts':
        source      => "${src}/mediacounts",
        destination => "${otherdir}/mediacounts",
        minute      => '41',
        user        => $user,
    }

    # Copies over files with pageview statistics per page and project,
    # using the current definition of pageviews, from an rsyncable location.
    dumps::web::fetches::job { 'pageview':
        source      => "${src}/{pageview,projectview}/legacy/hourly",
        destination => "${otherdir}/pageviews",
        minute      => '51',
        user        => $user,
    }

    # Copies over files with unique devices statistics per project,
    # using the last access cookie method, from an rsyncable location.
    dumps::web::fetches::job { 'unique_devices':
        source      => "${src}/unique_devices",
        destination => "${otherdir}/unique_devices",
        minute      => '31',
        user        => $user,
    }

    # Copies over clickstream files from an rsyncable location.
    dumps::web::fetches::job { 'clickstream':
        source      => "${src}/clickstream",
        destination => "${otherdir}/clickstream",
        hour        => '4',
        user        => $user,
    }
}
