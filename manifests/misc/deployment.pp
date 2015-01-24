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

