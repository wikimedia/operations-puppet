class role::puppetdb {
    include profile::base::production
    include profile::firewall
    include profile::nginx
    include profile::puppetdb::database
    include profile::puppetdb
    include profile::prometheus::postgres_exporter

    system::role { "puppetdb (postgres ${profile::puppetdb::database::db_role})":
        ensure      => 'present',
        description => 'PuppetDB server',
    }
    # I promise this really is temporary jbond 06-09-2023
    if $facts['networking']['fqdn'] in ['puppetdb1002.eqiad.wmnet', 'puppetdb2002.codfw.wmnet'] {
        motd::message { 'This server is not currently active please use puppetdb[12]003 instead':
            priority => 99,
            color    => 'red',
        }
    }
}
