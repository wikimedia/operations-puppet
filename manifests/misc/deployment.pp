# misc/deployment-host.pp

# deployment hosts

class misc::deployment::fatalmonitor {
    file {
        '/usr/local/bin/fatalmonitor':
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///files/misc/scripts/fatalmonitor';
    }
}

class misc::deployment::passwordscripts {
    include passwords::misc::scripts
    $cachemgr_pass = $passwords::misc::scripts::cachemgr_pass
    $mysql_root_pass = $passwords::misc::scripts::mysql_root_pass
    $nagios_sql_pass = $passwords::misc::scripts::nagios_sql_pass
    $webshop_pass = $passwords::misc::scripts::webshop_pass
    $wikiadmin_pass = $passwords::misc::scripts::wikiadmin_pass
    $wikiuser2_pass = $passwords::misc::scripts::wikiuser2_pass
    $wikiuser_pass = $passwords::misc::scripts::wikiuser_pass
    $wikiuser_pass_nagios = $passwords::misc::scripts::wikiuser_pass_nagios
    $wikiuser_pass_real = $passwords::misc::scripts::wikiuser_pass_real

    file {
        '/usr/local/bin/cachemgr_pass':
            owner   => 'root',
            group   => 'wikidev',
            mode    => '0550',
            content => template('misc/passwordScripts/cachemgr_pass.erb');
        '/usr/local/bin/mysql_root_pass':
            owner   => 'root',
            group   => 'wikidev',
            mode    => '0550',
            content => template('misc/passwordScripts/mysql_root_pass.erb');
        '/usr/local/bin/nagios_sql_pass':
            owner   => 'root',
            group   => 'wikidev',
            mode    => '0550',
            content => template('misc/passwordScripts/nagios_sql_pass.erb');
        '/usr/local/bin/webshop_pass':
            owner   => 'root',
            group   => 'wikidev',
            mode    => '0550',
            content => template('misc/passwordScripts/webshop_pass.erb');
        '/usr/local/bin/wikiadmin_pass':
            owner   => 'root',
            group   => 'wikidev',
            mode    => '0550',
            content => template('misc/passwordScripts/wikiadmin_pass.erb');
        '/usr/local/bin/wikiuser2_pass':
            owner   => 'root',
            group   => 'wikidev',
            mode    => '0550',
            content => template('misc/passwordScripts/wikiuser2_pass.erb');
        '/usr/local/bin/wikiuser_pass':
            owner   => 'root',
            group   => 'wikidev',
            mode    => '0550',
            content => template('misc/passwordScripts/wikiuser_pass.erb');
        '/usr/local/bin/wikiuser_pass_nagios':
            owner   => 'root',
            group   => 'wikidev',
            mode    => '0550',
            content => template('misc/passwordScripts/wikiuser_pass_nagios.erb');
        '/usr/local/bin/wikiuser_pass_real':
            owner   => 'root',
            group   => 'wikidev',
            mode    => '0550',
            content => template('misc/passwordScripts/wikiuser_pass_real.erb');
    }
}

class misc::deployment::l10nupdate {
    require scap::master

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
            source => 'puppet:///files/misc/l10nupdate/l10nupdate';
        '/usr/local/bin/l10nupdate-1':
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///files/misc/l10nupdate/l10nupdate-1';
        '/usr/local/bin/sync-l10nupdate':
            ensure => 'absent';
        '/usr/local/bin/sync-l10nupdate-1':
            ensure => 'absent';
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
        '/etc/logrotate.d/l10nupdate':
            source => 'puppet:///files/logrotate/l10nupdate',
            mode   => '0444';
    }
}

class misc::deployment::scap_proxy {
    include rsync::server
    include network::constants

    rsync::server::module { 'common':
        path        => '/srv/mediawiki',
        read_only   => 'true',
        hosts_allow => $::network::constants::mw_appserver_networks;
    }
}
