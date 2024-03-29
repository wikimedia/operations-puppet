# SPDX-License-Identifier: Apache-2.0
# == Class bigtop::hadoop::users
# Ensures that all users in the posix group $group
# have HDFS user directories at /user/<username>
#
# == Parameters
# $groups       - Space separated group names in which all users should have
#                 access to Hadoop.  Default: hadoop
#
# == Usage
# The following will ensure that all users in the
# posix groups 'my-analytics-group' and 'my-analytics-admin-group'
# have HDFS user directories.
#
#    class { 'bigtop::hadoop::users':
#        groups => 'my-analytics-group my-analytics-admin-group',
#    }
#
class bigtop::hadoop::users(
    $groups = ['hadoop'],
) {
    Class['bigtop::hadoop'] -> Class['bigtop::hadoop::users']

    file { '/usr/local/bin/create_hdfs_user_directories.sh':
        source => 'puppet:///modules/bigtop/hadoop/create_hdfs_user_directories.sh',
        owner  => 'root',
        group  => 'hdfs',
        mode   => '0554',
    }

    kerberos::exec { 'create_hdfs_user_directories':
        command   => "/usr/local/bin/create_hdfs_user_directories.sh --verbose ${groups}",
        unless    => "/usr/local/bin/create_hdfs_user_directories.sh --check-for-changes ${groups}",
        user      => 'hdfs',
        logoutput => true,
        timeout   => 120,
    }
}
