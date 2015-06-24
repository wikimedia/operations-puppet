# sets up a static HTML version of the old Bugzilla install
# T85140
class bugzilla_static {

    file { '/srv/org/wikimedia/static-bugzilla':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755';
    }

    file { '/srv/org/wikimedia/static-bugzilla/index.html':
        ensure => present,
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0400',
        source => 'puppet:///modules/bugzilla_static/static-bz-index.html';
    }

    include ::apache::mod::rewrite
    include ::apache::mod::headers

    apache::site { 'static-bugzilla.wikimedia.org':
        content  => template('bugzilla_static/apache/static-bugzilla.wikimedia.org.erb'),
        priority => 20,
    }

}
