# filtertags: labs-project-deployment-prep labs-project-automation-framework labs-project-toolsbeta
class role::puppetmaster::puppetdb {
    include ::standard
    include ::profile::base::firewall
    include ::profile::puppetdb::database
    include ::profile::puppetdb

    # Monitor the Postgresql replication lag

    system::role { "puppetmaster::puppetdb (postgres ${::profile::puppetdb::role})":
        ensure      => 'present',
        description => 'PuppetDB server',
    }
}
