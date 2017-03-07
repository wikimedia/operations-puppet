# == Class authdns::lint
# A class to lint Wikimedia's authoritative DNS system
#
class authdns::lint {
    include ::geoip

    class authdns {
        config_dir  => '/var/lib/gdnsd/testconfig',
        clone_data  => false,
        run_service => false,
    }
}
