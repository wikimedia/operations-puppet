# a webserver for misc. (PHP) apps
class role::webserver_misc_apps {

    system::role { 'webserver_misc_apps':
        description => 'WMF misc apps web server'
    }

    include ::standard
    include ::profile::base::firewall

    include ::profile::wikimania_scholarships
    include ::profile::iegreview
    include ::profile::grafana::production
    include ::profile::kafka::analytics::burrow # kafka::analytics::burrow is a Kafka consumer lag monitor
    include ::profile::racktables

}
