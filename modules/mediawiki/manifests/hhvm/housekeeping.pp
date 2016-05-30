# === Class mediawiki::hhvm::housekeeping
#
# This class contains all crons and other housekeeping execs we may
# want to run against hhvm or its admin port.
class mediawiki::hhvm::housekeeping {
    # This command is useful prune the hhvm bytecode cache from old tables that
    # are just left around

    file { '/usr/local/sbin/hhvm_cleanup_cache':
        source => 'puppet:///modules/mediawiki/hhvm/cleanup_cache',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

}
