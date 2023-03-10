# SPDX-License-Identifier: Apache-2.0
# @summary Uninstalls l10nupdate.
class scap::l10nupdate () {
    # HACK: On Cloud VPS, the l10nupdate user is defined in LDAP, so
    # trying to delete it locally fails with a confusing error message.
    if $::realm != 'labs' {
        user { 'l10nupdate':
            ensure => absent,
        }

        group { 'l10nupdate':
            ensure => absent,
        }
    }

    file { '/home/l10nupdate':
        ensure  => absent,
        recurse => true,
        purge   => true,
        force   => true,
    }

    systemd::timer::job { 'l10nupdate':
        ensure          => absent,
        description     => 'l10nupdate',
        user            => 'l10nupdate',
        command         => '/usr/local/bin/l10nupdate-1 --verbose',
        logfile_basedir => '/var/log/l10nupdatelog/',
        logfile_name    => 'l10nupdate.log',
        interval        => { 'start' => 'OnCalendar', 'interval' => 'Mon,Tue,Wed,Thu *-*-* 02:00:00'},
    }

    file { '/usr/local/bin/l10nupdate':
        ensure => absent,
    }
    file { '/usr/local/bin/l10nupdate-1':
        ensure => absent,
    }

    sudo::user { 'l10nupdate':
        ensure     => absent,
        user       => 'l10nupdate',
        privileges => [],
    }

    # Make sure the log directory exists and has adequate permissions.
    # It's called l10nupdatelog because /var/log/l10nupdate was used
    # previously so it'll be an existing file on some systems.
    # Also create the dir for the SVN checkouts, and set up log rotation
    file { '/var/log/l10nupdatelog':
        ensure  => absent,
        recurse => true,
        purge   => true,
        force   => true,
    }
    file { '/var/lib/l10nupdate':
        ensure  => absent,
        recurse => true,
        purge   => true,
        force   => true,
    }
}
