# == Class scap::clean
#
# This is a class that removes any vestiges of legacy scap from production
# systems that may cause issues. This class can be removed after it is
# run in production.
#
# Scap has a long history, let's make sure we hide that.

class scap::clean {
    $old_binstubs = [
        '/usr/local/bin/mwversionsinuse',
        '/usr/local/bin/refreshCdbJsonFiles',
        '/usr/local/bin/scap-rebuild-cdbs',
        '/usr/local/bin/scap-recompile',
        '/usr/local/bin/sync-common',
    ]

    file { $old_binstubs:
        ensure => absent,
    }

    file { '/srv/deployment/scap':
        ensure => absent,
        force  => true,
    }
}
