class dumps::web::fetches::phab(
    $src = undef,
    $miscdatasetsdir = undef,
    $user = undef,
) {
    # Copies over the phabricator dumps from an rsyncable location.
    dumps::web::fetches::job { 'phabdumps':
        source      => "${src}/phabricator_public.dump",
        destination => "${miscdatasetsdir}/misc",
        delete      => false,
        minute      => '14',
        user        => $user,
    }
}
