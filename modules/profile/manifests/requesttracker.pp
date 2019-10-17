# server running "Request Tracker"
# https://bestpractical.com/request-tracker
class profile::requesttracker {

    include ::passwords::misc::rt

    if os_version('debian == buster') {
        require_package('libapache2-mod-perl2', 'libapache2-mod-scgi')
        $cgi_module = 'scgi'
    } else {
        $cgi_module = 'fastcgi'
    }

    class { '::httpd':
        modules => ['headers', 'rewrite', 'perl', $cgi_module],
    }

    class { '::requesttracker':
        apache_site => 'rt.wikimedia.org',
        dbhost      => 'm1-master.eqiad.wmnet',
        dbport      => '',
        dbuser      => $passwords::misc::rt::rt_mysql_user,
        dbpass      => $passwords::misc::rt::rt_mysql_pass,
    }

    ferm::service { 'rt-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }
}

