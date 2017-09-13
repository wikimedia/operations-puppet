# serve dumps of revision content from restbase in html format
class dumps::web::htmldumps {

    # nginx serving these via http only, with another host
    # proxying all requests. can't use the standard dumps nginx
    # manifest. all of the code below is for this setup, which
    # is temporary.

    file { '/srv/www':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'www-data',
    }

    file { '/srv/www/htmldumps':
        ensure => directory,
        mode   => '0775',
        owner  => 'root',
        group  => 'htmldumps-admin',
    }

    # don't know if we want bw limits etc so let's slap 'extras'
    # on there
    class { '::nginx':
        variant => 'extras',
    }

    logrotate::conf { 'htmldumps-nginx':
        ensure => present,
        source => 'puppet:///modules/dumps/web/xmldumps/logrotate.conf',
    }

    nginx::site { 'htmldumps':
        source => 'puppet:///modules/dumps/web/htmldumps/nginx.conf',
        notify => Service['nginx'],
    }
}
