# bugzilla cron jobs

class bugzilla::crons ($bz_path, $whine = 'whine.pl', $collectstats = 'collectstats.pl'){

    cron { 'bugzilla_whine':
        command => "${bz_path}/${whine}",
        user    => 'root',
        minute  => '15',
    }

    # 2 cron jobs to generate charts data
    # See https://bugzilla.wikimedia.org/29203

    # 1) get statistics for the day:
    cron { 'bugzilla_collectstats':
        command => "${bz_path}/${collectstats}",
        user    => 'root',
        hour    => '0',
        minute  => '5',
        weekday => [ 1, 2, 3, 4, 5, 6 ] # Monday - Saturday
    }

    # 2) on sunday, regenerates the whole statistics data
    cron { 'bugzilla_collectstats_regenerate':
        command => "${bz_path}/${collectstats} --regenerate",
        user    => root,
        hour    => 0,
        minute  => 5,
        weekday => 0  # Sunday
    }
}

