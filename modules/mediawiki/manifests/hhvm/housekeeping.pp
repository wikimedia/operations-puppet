# === Class mediawiki::hhvm::housekeeping
#
# This class contains all crons and other housekeeping execs we may
# want to run against hhvm or its admin port.
class mediawiki::hhvm::housekeeping {
    # Ensure that jemalloc heap profiling is disabled. This means that
    # if you want to capture heap profiles, you have to disable Puppet.
    # But this way we can be sure we're not forgetting to turn it off.

    exec { 'ensure_jemalloc_prof_deactivated':
        command  => '/usr/bin/curl -fs http://localhost:9002/jemalloc-prof-deactivate',
        onlyif   => '! /usr/bin/curl -fs http://localhost:9002/jemalloc-stats-print | grep -Pq "opt.prof(_active)?: false"',
        provider => 'shell',
        require  => [Service['hhvm'],Service['apache2']],
    }

    # This command is useful prune the hhvm bytecode cache from old tables that
    # are just left around

    file { '/usr/local/sbin/hhvm_cleanup_cache':
        source => 'puppet:///modules/mediawiki/hhvm/cleanup_cache',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # Temporary - remove the old script location
    file { '/usr/local/bin/hhvm_cleanup_cache':
        ensure => absent,
    }
}
