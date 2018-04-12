# Defines rsync jobs that fetch various datasets from stat1005,
# generated locally by ezachte.
class dumps::web::fetches::stat_dumps(
    $src = undef,
    $miscdatasetsdir = undef,
    $user = undef,
) {
    dumps::web::fetches::job { 'wikistats_1.0':
        source      => "${src}/wikistats_1.0",
        destination => "${miscdatasetsdir}/wikistats_1.0",
        minute      => '11',
        user        => $user,
    }

    dumps::web::fetches::job { 'pagecounts-ez-merged':
        source      => "${src}/pagecounts-ez/merged",
        destination => "${miscdatasetsdir}/pagecounts-ez/merged",
        minute      => '21',
        user        => $user,
    }

    dumps::web::fetches::job { 'pagecounts-ez-projectcounts':
        source      => "${src}/pagecounts-ez/projectcounts",
        destination => "${miscdatasetsdir}/pagecounts-ez/projectcounts",
        minute      => '31',
        user        => $user,
    }

    dumps::web::fetches::job { 'pagecounts-ez-projectviews':
        source      => "${src}/pagecounts-ez/projectviews",
        destination => "${miscdatasetsdir}/pagecounts-ez/projectviews",
        minute      => '41',
        user        => $user,
    }

    # Wiki Loves Monuments
    dumps::web::fetches::job { 'media-contestwinners-WLM':
        source      => "${src}/media/contest_winners/WLM",
        destination => "${miscdatasetsdir}/media/contest_winners/WLM",
        minute      => '51',
        user        => $user,
    }

    # Wiki Loves Africa
    dumps::web::fetches::job { 'media-contestwinners-WLA':
        source      => "${src}/media/contest_winners/WLA",
        destination => "${miscdatasetsdir}/media/contest_winners/WLA",
        minute      => '61',
        user        => $user,
    }

    # Wiki Loves Earth
    dumps::web::fetches::job { 'media-contestwinners-WLE':
        source      => "${src}/media/contest_winners/WLE",
        destination => "${miscdatasetsdir}/media/contest_winners/WLE",
        minute      => '1',
        user        => $user,
    }

}
