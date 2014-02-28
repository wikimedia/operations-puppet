# RT - Request Tracker
# This will create a server running RT with Apache
# and a Wikimedia configuration
class requesttracker (
    $dbuser,
    $dbpass,
    $apache_site = 'rt.wikimedia.org',
    $dbhost      = 'localhost',
    $dbport      = '3306',
    $datadir     = '/var/lib/mysql'
) {

    $rt_mysql_user = $dbuser
    $rt_mysql_pass = $dbpass
    $rt_mysql_host = $dbhost
    $rt_mysql_port = $dbport


    include requesttracker::packages
    include requesttracker::config
    include requesttracker::forms
    include requesttracker::plugins

    class { 'requesttracker::apache':
        apache_site => $apache_site,
    }

}

