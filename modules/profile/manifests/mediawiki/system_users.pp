# Class used to install system users for mediawiki
class profile::mediawiki::system_users(
    Wmflib::Ensure $ensure = lookup('profile::mediawiki::system_users::ensure', {'default_value' => 'present'}),
    String $spiderpig_user  = lookup('profile::mediawiki::system_users::spiderpig_user', {'default_value' => 'spiderpig'}),
){
    # Create the mwbuilder user. This is the user that is allowed to run docker-pusher to publish
    # the images, and that should run the tasks in repos/releng/release.
    group { 'mwbuilder':
        ensure => $ensure,
        system => true,
    }
    user { 'mwbuilder':
        ensure     => $ensure,
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
        ensure     => $ensure,
        gid        => 'mwbuilder',
        shell      => '/bin/false',
        comment    => '',
        home       => '/srv/mwpresync',
        managehome => true,
        system     => true,
    }
    git::userconfig { '.gitconfig for mwpresync user':
        homedir  => '/srv/mwpresync',
        settings => {
            'user' => {
                'name'  => 'MediaWiki PreSync',
                'email' => "mwpresync@${::fqdn}",
            },
        },
        require  => User['mwpresync']
    }

    # TODO: Once we are in bookworm+, switch the following 2 resources to systemd-sysuser
    # Create the spiderpig user/group combo
    # The class is explicitly defining and default to 929 as uid/gid for spiderpig.
    # Don't mess with those numbers unless there is a very good reason to do so
    group { $spiderpig_user:
        gid    => 929, # Explicitly defined to avoid cross deployment hosts issues
        system => true,
    }
    user { 'spiderpig':
        ensure     => $ensure,
        uid        => 929, # Explicitly defined to avoid cross deployment hosts issues
        gid        => $spiderpig_user,
        comment    => 'SpiderPig jobrunner/apiserver',
        home       => '/var/lib/spiderpig',
        managehome => true,
        system     => true,
    }
}
