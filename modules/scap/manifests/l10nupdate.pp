# = class: scap::l10nupdate
#
# Sets up files and cron required to do l10nupdate
class scap::l10nupdate {
    cron { 'l10nupdate':
        ensure  => present,
        command => '/usr/local/bin/l10nupdate-1 --verbose >> /var/log/l10nupdatelog/l10nupdate.log 2>&1',
        user    => 'l10nupdate',
        hour    => 2,
        minute  => 0;
    }

    file {
        '/usr/local/bin/l10nupdate':
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/scap/l10nupdate';
        '/usr/local/bin/l10nupdate-1':
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/scap/l10nupdate-1';
        # add ssh keypair for l10nupdate user from fenari for RT-5187
        '/home/l10nupdate/.ssh/id_rsa':
            owner  => 'l10nupdate',
            group  => 'l10nupdate',
            mode   => '0400',
            source => 'puppet:///private/ssh/tin/l10nupdate/id_rsa';
        '/home/l10nupdate/.ssh/id_rsa.pub':
            owner  => 'l10nupdate',
            group  => 'l10nupdate',
            mode   => '0444',
            source => 'puppet:///private/ssh/tin/l10nupdate/id_rsa.pub';
    }

    # Make sure the log directory exists and has adequate permissions.
    # It's called l10nupdatelog because /var/log/l10nupdate was used
    # previously so it'll be an existing file on some systems.
    # Also create the dir for the SVN checkouts, and set up log rotation
    file { '/var/log/l10nupdatelog':
            ensure => directory,
            owner  => 'l10nupdate',
            group  => 'wikidev',
            mode   => '0664';
        '/var/lib/l10nupdate':
            ensure => directory,
            owner  => 'l10nupdate',
            group  => 'wikidev',
            mode   => '0755';
        '/var/lib/l10nupdate/caches':
            ensure => directory,
            owner  => $::mediawiki::users::web,
            group  => $::mediawiki::users::web,
            mode   => '0755';
        '/etc/logrotate.d/l10nupdate':
            source => 'puppet:///modules/scap/l10nupdate.logrotate',
            mode   => '0444';
    }
}
