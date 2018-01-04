class role::planet_httpd {

    include ::standard
    include ::profile::base::firewall
    include ::profile::planet::httpd

    system::role { 'planet_server':
        description => 'Planet-venus or rawdog RSS feed aggregator'
    }
}
