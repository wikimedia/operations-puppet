# role classes for dataset servers

# a dumps primary server has dumps generated on this host; other directories
# of content may or may not be generated here (but should all be eventually)
# mirrors to the public should not be provided from here via rsync
class role::dataset::primary {
    include role::dataset::common

    system::role { 'dataset::primary':
        description => 'dataset primary host',
    }

    class {'dataset':}
}

