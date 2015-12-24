# a dumps secondary server may be a primary source of content for a small
# number of directories (but best is not at all)
# mirrors to the public should be provided from here via rsync
class role::dataset::secondary {
    system::role { 'role::dataset::secondary':
        description => 'dataset secondary host',
    }

    $rsync = {
        'public' => true,
        'peers'  => true,
    }
    $grabs = {
    }
    $uploads = {
    }

    class { 'dataset':
        rsync   => $rsync,
        grabs   => $grabs,
        uploads => $uploads,
    }
}
