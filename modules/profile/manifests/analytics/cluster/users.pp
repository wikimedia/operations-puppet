# == Class profile::analytics::cluster::users
#
# Installs any special system users needed on analytics namenodes or clients.
# This is used for ensuring that users exist for use in HDFS.  Once
# analytics cluster is fully upgraded to Buster (T220971), these users
# should also be declared in admin module data.yaml.
#
# NOTE: Puppet does not manage creation of system user HDFS home directories.
# you will need to do this manually.  To do so, run from any Hadoop node:
#   sudo -u hdfs hdfs dfs -mkdir /user/$user && \
#   sudo -u hdfs hdfs dfs -chown $user:$group /user/$user
# And optionally:
#   sudo -u hdfs hdfs dfs -chmod 775 /user/$user
#
class profile::analytics::cluster::users {

    # When Kerberos is enabled, indexation jobs will run on workers as user 'druid'.
    class { '::druid::bigtop::hadoop::user': }

    $users = {
        # The analytics user will be used to run any Analytics
        # job running on Yarn/HDFS (as replacement for 'hdfs').
        # T220971
        # The analytics user needs to be able to change group ownership of
        # directories that it owns to analytics:druid. The Hive workflows/actions
        # that we use for Druid leverage a separate scratch dir to work on the data,
        # that is moved and chowned as last step to its final location on HDFS.
        # If the analytics user is not in the druid group it will not be able (via Hive etc..)
        # to chgrp the final directory (and its files) to a group like 'druid'.
        'analytics' => {
            'uid'     => 906,
            'gid'     => 906,
            # The druid group is declared in druid::bigtop::hadoop::user.
            'groups'  => 'druid',
            'require' => Group['druid']
        },
        # The analytics-privatedata user will be used to run
        # cronjobs and similar by users.
        # T238306
        'analytics-privatedata' => {
            'uid' => 909,
            'gid' => 909,
        },
        # analytics-search user will be used to deploy
        # wikimedia/discovery/analytics into HDFS.
        # The analytics-search-users group will be allowed to
        # sudo -u analytics-search.
        'analytics-search' => {
            'uid' => 911,
            'gid' => 911,
        },
        # The analytics-product user will be used to run
        # cronjobs and similar by Product Analytics.
        # T255039
        'analytics-product' => {
            'uid' => 910,
            'gid' => 910,
        },
    }

    # Declare each of the system users and their groups.
    $users.each |String $user, Hash $properties| {
        # Placeholder to reserve the uid/gid once T231067 is complete.
        if debian::codename::ge('buster') {
            $uid = $properties['uid']
            $gid = $properties['gid']
        } else {
            $uid = undef
            $gid = undef
        }

        $group = $properties['group'] ? {
            undef   => $user,
            default => $properties['group'],
        }

        $ensure = $properties['ensure'] ? {
            undef   => 'present',
            default => $properties['ensure'],
        }

        group { $group:
            ensure => $ensure,
            gid    => $gid,
        }

        user { $user:
            ensure  => $ensure,
            system  => true,
            uid     => $uid,
            gid     => $gid,
            groups  => $properties['groups'],
            require => $properties['require'],
        }
    }

}
