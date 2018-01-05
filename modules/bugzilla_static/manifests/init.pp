# sets up a static HTML version of the old Bugzilla install
# T85140
class bugzilla_static {

    ensure_resource('file', '/srv/org', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia/static-bugzilla', {'ensure' => 'directory' })

    file { '/srv/org/wikimedia/static-bugzilla/index.html':
        ensure => present,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0400',
        source => 'puppet:///modules/bugzilla_static/static-bz-index.html';
    }

    httpd::site { 'static-bugzilla.wikimedia.org':
        content  => template('bugzilla_static/apache/static-bugzilla.wikimedia.org.erb'),
        priority => 20,
    }

}
