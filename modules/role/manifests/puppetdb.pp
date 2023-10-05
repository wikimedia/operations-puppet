class role::puppetdb {
    include profile::base::production
    include profile::firewall
    include profile::nginx
    include profile::puppetdb::database
    include profile::puppetdb
    include profile::prometheus::postgres_exporter
    include profile::sre::os_updates

    system::role { "puppetdb (postgres ${profile::puppetdb::database::db_role})":
        ensure      => 'present',
        description => 'PuppetDB server',
    }
}
