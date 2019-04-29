# filtertags: labs-project-deployment-prep labs-project-automation-framework labs-project-toolsbeta
class role::puppetmaster::puppetdb {
    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::puppetdb::database
    include ::profile::puppetdb
    include ::profile::rsyslog::kafka_shipper

    system::role { "puppetmaster::puppetdb (postgres ${::profile::puppetdb::database::role})":
        ensure      => 'present',
        description => 'PuppetDB server',
    }
}
