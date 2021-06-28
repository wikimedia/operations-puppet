# filtertags: labs-project-deployment-prep labs-project-automation-framework labs-project-toolsbeta
class role::puppetmaster::puppetdb {
    include profile::standard
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
