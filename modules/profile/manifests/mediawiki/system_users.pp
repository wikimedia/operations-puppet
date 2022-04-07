# Class used to install system users for mediawiki
class profile::mediawiki::system_users(Wmflib::Ensure $ensure = lookup('profile::mediawiki::system_users::ensure', {'default_value' => 'present'})) {
    # Create the mwbuilder user. This is the user that is allowed to run docker-pusher to publish
    # the images, and that should run the tasks in mediawiki/tools/release.
    group { 'mwbuilder':
        ensure => present,
        system => true,
    }
    user { 'mwbuilder':
        ensure     => present,
        gid        => 'mwbuilder',
        shell      => '/bin/false',
        comment    => '',
        home       => '/srv/mwbuilder',
        managehome => true,
        system     => true,
    }
}
