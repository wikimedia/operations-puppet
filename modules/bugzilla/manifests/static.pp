# sets up a static HTML version of the old Bugzilla install
# T85140
class bugzilla::static {

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
        source => 'puppet:///modules/bugzilla/static-bz-index.html';
    }

    include ::apache::mod::rewrite
    include ::apache::mod::headers

    apache::site { 'static-bugzilla.wikimedia.org':
        content  => template('bugzilla/apache/static-bugzilla.wikimedia.org.erb'),
        priority => 20,
    }

}
