# == Class druid::cdh::hadoop::setup
# Ensures that the druid user exists and that
# druid directories exist in HDFS.  This should
# only be included on Hadoop NameNodes.
#
class druid::cdh::hadoop::setup {
    Class['cdh::hadoop'] -> Class['druid::cdh::hadoop::setup']

    # Make sure that a druid user exists on hadoop namenodes so that
    # files can be owned by druid.
    group { 'druid':
        ensure => 'present',
        system => true,
    }
    user { 'druid':
        ensure     => 'present',
        gid        => 'druid',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
        require    => Group['druid'],
    }

    # Ensure that HDFS directories for druid deep storage are created.
    cdh::hadoop::directory { '/user/druid':
        owner   => 'druid',
        group   => 'hadoop',
        mode    => '0775',
        require => User['druid'],
    }
    cdh::hadoop::directory { '/user/druid/deep-storage':
        owner   => 'druid',
        group   => 'hadoop',
        mode    => '0775',
        require => Cdh::Hadoop::Directory['/user/druid'],
    }
}
