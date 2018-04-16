# Defines rsync jobs that fetch various datasets from stat1005,
# generated locally by ezachte.
class dumps::web::fetches::stat_dumps(
    $src = undef,
    $miscdatasetsdir = undef,
    $user = undef,
) {
    dumps::web::fetches::job { 'wikistats_1':
        source      => "${src}/wikistats_1",
        destination => "${miscdatasetsdir}/wikistats_1",
        minute      => '11',
        user        => $user,
    }

    dumps::web::fetches::job { 'pagecounts-ez':
        source      => "${src}/pagecounts-ez",
        destination => "${miscdatasetsdir}/pagecounts-ez",
        minute      => '21',
        user        => $user,
    }

    # Wiki Loves * (Monuments, Africa, Earth, etc.)
    dumps::web::fetches::job { 'media-contestwinners':
        source      => "${src}/media/contest_winners",
        destination => "${miscdatasetsdir}/media/contest_winners",
        minute      => '31',
        user        => $user,
    }

}
