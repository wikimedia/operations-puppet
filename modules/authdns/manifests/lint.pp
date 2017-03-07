# == Class authdns::lint
# A class to lint Wikimedia's authoritative DNS system
#
class authdns::lint {
    class { 'authdns':
        config_dir  => '/var/lib/gdnsd/testconfig',
        real_server => false,
    }
}
