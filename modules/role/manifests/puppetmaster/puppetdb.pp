class role::puppetmaster::puppetdb {
    include profile::base::production
    include profile::base::firewall
    include profile::nginx
    include profile::puppetdb::database
    include profile::puppetdb
    include profile::prometheus::postgres_exporter

    system::role { "puppetmaster::puppetdb (postgres ${profile::puppetdb::database::db_role})":
        ensure      => 'present',
        description => 'PuppetDB server',
    }
}
