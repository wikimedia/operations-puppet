# sets up a static HTML version of the old Bugzilla install
# T85140
class bugzilla::static {

    file { '/srv/org/wikimedia/static-bugzilla':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755';
    }

    apache::site { 'static-bugzilla.wikimedia.org':
        content  => template('bugzilla/apache/static-bugzilla.wikimedia.org.erb'),
        priority => 20,
    }

}
