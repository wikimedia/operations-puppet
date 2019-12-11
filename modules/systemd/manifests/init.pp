# == Class systemd ==
#
# This class defines a guard against running on non-systemd systems, a few
# constants, and the check_journal_pattern nrpe plugin.
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

    file { '/usr/local/lib/nagios/plugins/check_journal_pattern':
        ensure => present,
        source => 'puppet:///modules/systemd/check_journal_pattern',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }
}
