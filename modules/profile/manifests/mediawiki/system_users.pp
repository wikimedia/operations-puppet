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
    # Create a second user that is used during the presync process.
    # This user will have the ability to prepare the mediawiki sources for train presync, and to
    # sudo to mwdeploy to distribute the code to the appservers.
    # Soon it will also be able to pre-pull images on the kubernetes nodes.
    # Please note we're using the "mwbuilder" group as its primary group, so that we group these system users
    # in the same primary group.
    user { 'mwpresync':
        ensure     => present,
        gid        => 'mwbuilder',
        shell      => '/bin/false',
        comment    => '',
        home       => '/srv/mwpresync',
        managehome => true,
        system     => true,
    }
}
