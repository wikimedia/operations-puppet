# RT - Request Tracker
# This will create a server running RT with Apache
# and a Wikimedia configuration
class requesttracker (
    $dbuser,
    $dbpass,
    $site = 'rt.wikimedia.org',
    $dbhost = 'localhost',
    $dbport = '3306',
    $datadir = '/var/lib/mysql'
) {

    $rt_mysql_user = $dbuser
    $rt_mysql_pass = $dbpass
    $rt_mysql_host = $dbhost
    $rt_mysql_port = $dbport


    include requesttracker::packages,
            requesttracker::config,
            requesttracker::forms,
            requesttracker::plugins

    class { 'requesttracker::apache':
        site =>  $site,
    }

}

