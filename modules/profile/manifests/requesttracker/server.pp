# server running "Request Tracker"
# https://bestpractical.com/request-tracker
class profile::requesttracker::server {

    include ::passwords::misc::rt

    class { '::requesttracker':
        apache_site => 'rt.wikimedia.org',
        dbhost      => 'm1-master.eqiad.wmnet',
        dbport      => '',
        dbuser      => $passwords::misc::rt::rt_mysql_user,
        dbpass      => $passwords::misc::rt::rt_mysql_pass,
    }

    include ::profile::base::firewall

    ferm::service { 'rt-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$PRODUCTION_NETWORKS',
    }
}

