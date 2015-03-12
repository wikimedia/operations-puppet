# = class: scap::scripts
#
# Sets up commonly used scripts useful on scap masters
# FIXME: Why isn't this in a package?
# FIXME: Why are these in a combination of languages?
# FIXME: Why are these named-like-this and namedLikeThis
# FIXME: Why man pages for some but not all?
class scap::scripts {
    require misc::deployment::passwordscripts
    require mediawiki::users

    package { ['libwww-perl', 'libnet-dns-perl']:
        ensure => present;
    }

    file {
        '/usr/local/bin/clear-profile':
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/scap/clear-profile';
        '/usr/local/bin/dologmsg':
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/scap/dologmsg';
        '/usr/local/bin/mwgrep':
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/scap/mwgrep';
        '/usr/local/bin/deploy2graphite':
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/scap/deploy2graphite';
        '/usr/local/bin/foreachwiki':
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/scap/foreachwiki';
        '/usr/local/bin/foreachwikiindblist':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            content => template('scap/foreachwikiindblist.erb');
        '/usr/local/bin/mwscript':
            owner    => 'root',
            group    => 'root',
            mode     => '0555',
            source   => 'puppet:///modules/scap/mwscript';
        '/usr/local/bin/mwscriptwikiset':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            source  => 'puppet:///modules/scap/mwscriptwikiset';
        '/usr/local/bin/notifyNewProjects':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            source  => 'puppet:///modules/scap/notifyNewProjects';
        '/usr/local/bin/purge-varnish':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            source  => 'puppet:///modules/scap/purge-varnish';
        '/usr/local/bin/refreshWikiversionsCDB':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            source  => 'puppet:///modules/scap/refreshWikiversionsCDB';
        '/usr/local/bin/reset-mysql-slave':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            source  => 'puppet:///modules/scap/reset-mysql-slave';
        '/usr/local/bin/set-group-write':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            source  => 'puppet:///modules/scap/set-group-write';
        '/usr/local/bin/sql':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            source  => 'puppet:///modules/scap/sql';
        '/usr/local/bin/sqldump':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            source  => 'puppet:///modules/scap/sqldump';
        '/usr/local/bin/udprec':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            source  => 'puppet:///modules/scap/udprec';
        '/usr/local/sbin/set-group-write2':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            source  => 'puppet:///modules/scap/set-group-write2';
        '/usr/local/bin/updateinterwikicache':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            source  => 'puppet:///modules/scap/updateinterwikicache';
        # Manpages
        # Need to be generated manually using make in modules/scap/files/manpages
        '/usr/local/share/man/man1':
            ensure  => 'directory',
            recurse => true,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            source  => 'puppet:///modules/scap/manpages/man';
        '/usr/local/bin/sudo-withagent':
            owner   => 'root',
            group   => 'root',
            mode    => '0555',
            source  => 'puppet:///modules/scap/sudo-withagent';
        '/usr/local/lib/mw-deployment-vars.sh':
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => template('scap/mw-deployment-vars.erb');
    }
}
