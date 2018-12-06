# Defines rsync jobs that fetch various datasets from stat1007,
# generated locally by ezachte.
class dumps::web::fetches::stat_dumps(
    $src = undef,
    $miscdatasetsdir = undef,
    $user = undef,
) {
    # NOTE: rsync --delete is disabled for safety.  We don't
    # want an accidental removal of a file in source to
    # cause removal of a publicly available dataset.
    # We'll have to remove manually if we want to do that.

    dumps::web::fetches::job { 'wikistats_1':
        source      => "${src}/wikistats_1",
        destination => "${miscdatasetsdir}/wikistats_1",
        delete      => false,
        minute      => '11',
        user        => $user,
    }

    dumps::web::fetches::job { 'pagecounts-ez':
        source      => "${src}/pagecounts-ez",
        destination => "${miscdatasetsdir}/pagecounts-ez",
        delete      => false,
        minute      => '21',
        user        => $user,
    }

    # Wiki Loves * (Monuments, Africa, Earth, etc.)
    dumps::web::fetches::job { 'media-contestwinners':
        source      => "${src}/media/contest_winners",
        destination => "${miscdatasetsdir}/media/contest_winners",
        delete      => false,
        minute      => '31',
        user        => $user,
    }

}
