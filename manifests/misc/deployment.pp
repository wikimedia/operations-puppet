# misc/deployment-host.pp

# deployment hosts

class misc::deployment::passwordscripts {
    file { [
        '/usr/local/bin/cachemgr_pass':
        '/usr/local/bin/mysql_root_pass':
        '/usr/local/bin/nagios_sql_pass':
        '/usr/local/bin/webshop_pass':
        '/usr/local/bin/wikiadmin_pass':
        '/usr/local/bin/wikiuser2_pass':
        '/usr/local/bin/wikiuser_pass':
        '/usr/local/bin/wikiuser_pass_nagios':
        '/usr/local/bin/wikiuser_pass_real':
        ]:
            ensure => absent,
    }
}
