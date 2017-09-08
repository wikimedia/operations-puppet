# Serve html dumps generated from revision content in restbase
class htmldumps {

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

    nginx::site { 'htmldumps':
        source => 'puppet:///modules/dumps/web/nginx.htmldumps.conf',
        notify => Service['nginx'],
    }
}
