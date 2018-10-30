# https://bienvenida.wikimedia.org (T207816)
class profile::microsites::bienvenida {

    httpd::site { 'bienvenida.wikimedia.org':
        content => template('profile/bienvenida/apache-bienvenida.wikimedia.org.erb'),
    }

    ensure_resource('file', '/srv/org', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia/bienvenida', {'ensure' => 'directory' })

    #git::clone { 'wikimedia/campaigns/eswiki-2018':
    #    ensure    => 'latest',
    #    source    => 'gerrit',
    #    directory => '/srv/org/wikimedia/bienvenida',
    #    branch    => 'master',
    #}
}
