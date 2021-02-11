# Class: druid::bigtop::hadoop::deep_storage
#
# Ensure that an HDFS directory for Druid deep storage exists
# for a given druid cluster name.
#
# This should only be included on a Hadoop NameNode.
#
# == Parameters
#
# [*path*]
#   HDFS path of deep storage directory to create.
#   Default: /user/druid/deep-storage-${title}
#
define druid::bigtop::hadoop::deep_storage(
    $path = "/user/druid/deep-storage-${title}",
) {
    require ::druid::bigtop::hadoop::user

    bigtop::hadoop::directory { $path:
        owner => 'druid',
        group => 'hadoop',
        mode  => '0775',
    }
}
