# = class: scap::scripts
#
# Sets up commonly used scripts useful on scap masters
# FIXME: Why isn't this in a package?
# FIXME: Why are these in a combination of languages?
# FIXME: Why are these named-like-this and namedLikeThis
# FIXME: Why man pages for some but not all?
# FIXME: What on earth does MW have to do with this? Send it to the right module
class scap::scripts (
    Wmflib::Ensure $sql_scripts = present,
){

    file { '/usr/local/bin/logstash_checker.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/service/logstash_checker.py',
    }

    file { '/usr/local/bin/dologmsg':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/scap/dologmsg',
    }
    file { '/usr/local/bin/mwgrep':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/scap/mwgrep.py',
    }
    file { '/usr/local/bin/foreachwiki':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/scap/foreachwiki',
    }
    file { '/usr/local/bin/foreachwikiindblist':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/scap/foreachwikiindblist',
    }
    file { '/usr/local/bin/expanddblist':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/scap/expanddblist',
    }
    file { '/usr/local/bin/mwscript':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/scap/mwscript',
    }
    file { '/usr/local/bin/mwscriptwikiset':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/scap/mwscriptwikiset',
    }
    file { '/usr/local/bin/purge-varnish':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/scap/purge-varnish',
    }
    file { '/usr/local/bin/set-group-write':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/scap/set-group-write',
    }
    file { '/usr/local/bin/sql':
        ensure => $sql_scripts,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/scap/sql',
    }
    file { '/usr/local/bin/sqldump':
        ensure => $sql_scripts,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/scap/sqldump',
    }
    file { '/usr/local/sbin/set-group-write2':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/scap/set-group-write2',
    }
        # Manpages
        # Need to be generated manually using make in modules/scap/files/manpages
    file { '/usr/local/share/man/man1':
        ensure  => 'directory',
        recurse => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/scap/manpages/man',
    }
    file { '/usr/local/bin/sudo-withagent':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/scap/sudo-withagent',
    }
    file { '/usr/local/lib/mw-deployment-vars.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('scap/mw-deployment-vars.erb'),
    }

    # Clean up old cruft
    file { '/usr/local/bin/clear-profile':
        ensure => 'absent',
    }
    file { '/usr/local/bin/udprec':
        ensure => 'absent',
    }
}
