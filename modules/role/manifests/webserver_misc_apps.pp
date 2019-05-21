# a webserver for misc. apps
# (as opposed to static websites using webserver_misc_static)
class role::webserver_misc_apps {

    system::role { 'webserver_misc_apps':
        description => 'WMF misc apps web server'
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::misc_apps::httpd       # common webserver setup
    include ::profile::base::firewall::log
    include ::profile::wikimania_scholarships # https://scholarships.wikimedia.org
    include ::profile::iegreview              # https://iegreview.wikimedia.org
    include ::profile::racktables             # https://racktables.wikimedia.org
}
