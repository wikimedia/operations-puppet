# a dumps secondary server may be a primary source of content for a small
# number of directories (but best is not at all)
# mirrors to the public should be provided from here via rsync
class role::dataset::secondary {
    include role::dataset::common

    system::role { 'dataset::secondary':
        description => 'dataset secondary host',
    }

    class {'dataset':}
}
