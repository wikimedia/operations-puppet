# Class: profile::analytics::hdfs_tools
#
# Installs the analytics/hdfs-tools/deploy repository.
# This gets us some handy standalone tools for working with
# HDFS, including a custom hdfs rsync command.
#
class profile::analytics::hdfs_tools {
    # The analytics/hdfs-tools/deploy repo will deployed to this node via Scap3.
    # The analytics user/groups are deployed/managed by Scap.
    # The analytics_deploy SSH keypair files are stored in the private repo,
    # and since manage_user is true the analytics_deploy public ssh key
    # will be added to the 'analytics-deploy' user's ssh config. The rationale is to
    # have a single 'analytics' multi-purpose user that owns analytics deployment files.
    scap::target { 'analytics/hdfs-tools/deploy':
        deploy_user => 'analytics-deploy',
        key_name    => 'analytics_deploy',
        manage_user => true,
    }

    # analytics/hdfs-tools/deploy repository is deployed via scap at this path.
    # You must deploy this yourself; puppet will not do it for you.
    $path = '/srv/deployment/analytics/hdfs-tools/deploy'

    # Create a symlink in /usr/local/bin to hdfs-rsync for easy access!
    file { '/usr/local/bin/hdfs-rsync':
        target  => "${path}/bin/hdfs-rsync",
        require => Scap::Target['analytics/hdfs-tools/deploy'],
    }
}
