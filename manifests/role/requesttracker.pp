# RT: Request Tracker
# http://www.bestpractical.com/rt/
class role::requesttracker {

    system::role { 'requesttracker': description => 'RT (Request Tracker) server' }

    # config - labs vs. production
    case $::realm {
        'labs': {
            $rt_site = 'rt.wmflabs.org'
        }
        'production': {
            $rt_site = 'rt.wikimedia.org'
        }
        'default': {
            fail('unknown realm, should be labs or production')
        }
    }

    # main (init.pp from module)
    class { '::requesttracker':
        apache_site => $rt_site,
        dbhost      => 'localhost',
        dbport      => '3306',
        datadir     => '/var/lib/mysql',
    }

    monitor_service { 'RT-https':
        description   => 'RT-HTTPS',
        check_command => 'check_https_url!rt.wikimedia.org!/',
    }

}

