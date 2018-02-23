# a webserver for misc. apps
# (as opposed to static websites using webserver_misc_static)
class role::webserver_misc_apps {

    system::role { 'webserver_misc_apps':
        description => 'WMF misc apps web server'
    }

    include ::standard
    include ::profile::base::firewall

    include ::profile::wikimania_scholarships # https://scholarships.wikimedia.org
    include ::profile::iegreview              # https://iegreview.wikimedia.org
    include ::profile::grafana::production    # https://grafana.wikimedia.org
    include ::profile::racktables             # https://racktables.wikimedia.org

    include ::profile::kafka::monitoring
}
