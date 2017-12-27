# serve dumps of revision content from restbase in html format
class dumps::web::htmldumps(
    $htmldumps_server = undef,
) {

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

    nginx::site { 'htmldumps':
        content => template('dumps/web/htmldumps/nginx.conf.erb'),
        notify  => Service['nginx'],
    }
    include dumps::web::nginx_logrot
}
