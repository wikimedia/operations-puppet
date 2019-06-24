# == Class cdh::hadoop::journalnode
#
class cdh::hadoop::journalnode {
    Class['cdh::hadoop'] -> Class['cdh::hadoop::journalnode']

    # install jobtracker daemon package
    package { 'hadoop-hdfs-journalnode':
        ensure => 'installed'
    }

    # Ensure that the journanode edits directory has the correct permissions.
    file { $::cdh::hadoop::dfs_journalnode_edits_dir:
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
        require    => File[$::cdh::hadoop::dfs_journalnode_edits_dir],
    }
}
