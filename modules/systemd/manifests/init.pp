# == Class systemd ==
#
# This class defines a guard against running on non-systemd systems, a few
# constants, and the check_journal_pattern nrpe plugin.  It also defines an exec
# shared across all instantations of systemd::sysuser.
#
class systemd {
    if $::initsystem != 'systemd' {
        fail(
            "You can only use systemd resources on systems with systemd, got ${::initsystem}"
        )
    }

    # Directories for base units and overrides
    $base_dir = '/lib/systemd/system'
    $override_dir = '/etc/systemd/system'

    file { '/etc/sysusers.d':
        ensure  => directory,
        purge   => true,
        recurse => true,
    }

    exec { 'Refresh sysusers':
        command     => '/bin/systemd-sysusers',
        user        => 'root',
        refreshonly => true,
    }

    nrpe::plugin { 'check_journal_pattern':
        source => 'puppet:///modules/systemd/check_journal_pattern',
    }

    file { '/usr/local/bin/systemd-timer-mail-wrapper':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/systemd/systemd-timer-mail-wrapper.py',
    }
}
