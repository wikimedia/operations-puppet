# SPDX-License-Identifier: Apache-2.0
# == Class bigtop::hadoop::journalnode
#
class bigtop::hadoop::journalnode {
    Class['bigtop::hadoop'] -> Class['bigtop::hadoop::journalnode']

    # install jobtracker daemon package
    package { 'hadoop-hdfs-journalnode':
        ensure  => 'installed',
        require => User['hdfs'],
    }

    # Ensure that the journanode edits directory has the correct permissions.
    file { $::bigtop::hadoop::dfs_journalnode_edits_dir:
        ensure  => 'directory',
        owner   => 'hdfs',
        group   => 'hdfs',
        mode    => '0755',
        require => Package['hadoop-hdfs-journalnode'],
    }

    # install datanode daemon package
    service { 'hadoop-hdfs-journalnode':
        ensure     => 'running',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        alias      => 'journalnode',
        require    => File[$::bigtop::hadoop::dfs_journalnode_edits_dir],
    }
}
