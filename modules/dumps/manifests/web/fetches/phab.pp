class dumps::web::fetches::phab (
    $src = undef,
    $miscdatasetsdir = undef,
    $user = undef,
    $ensure = 'present',
) {
    # Copies over the phabricator dumps from an rsyncable location.
    dumps::web::fetches::job { 'phabdumps':
        ensure      => $ensure,
        source      => $src,
        destination => "${miscdatasetsdir}/misc",
        delete      => false,
        minute      => '14',
        user        => $user,
    }
}
