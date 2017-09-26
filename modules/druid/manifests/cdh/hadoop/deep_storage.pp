# Class: druid::cdh::hadoop::deep_storage
#
# Ensure that an HDFS directory for Druid deep storage exists
# for a given druid cluster name.
#
# This should only be included on a Hadoop NameNode.
#
# == Parameters
# $druid_cluster_name - If undef, The HDFS deep storage path will just be
#                       /user/druid/deep-storage, otherwise it will be
#                       /user/druid/deep-storage-${druid_cluster_name}.
#                       Default: $title.
#
define druid::cdh::hadoop::deep_storage(
    $druid_cluster_name = $title,
) {
    require ::druid::cdh::hadoop::user

    $deep_storage_path = $druid_cluster_name ? {
        undef   => '/user/druid/deep-storage',
        default => "/user/druid/deep-storage-${druid_cluster_name}",
    }

    cdh::hadoop::directory { $deep_storage_path:
        owner   => 'druid',
        group   => 'hadoop',
        mode    => '0775',
        require => Cdh::Hadoop::Directory['/user/druid'],
    }
}
