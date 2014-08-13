class mediawiki::sync {
    include ::misc::deployment::vars
    include ::mediawiki::users

    deployment::target { 'scap': }

    file { '/etc/profile.d/add_scap_to_path.sh':
        source => 'puppet:///modules/mediawiki/profile.d_add_scap_to_path.sh',
    }

    file { '/usr/local/apache':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        replace => false,
    }

    file { '/usr/local/apache/common':
        ensure => link,
        target => '/usr/local/apache/common-local',
    }

    file { '/a':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    file { '/a/common':
        ensure  => link,
        target  => '/usr/local/apache/common-local',
        owner   => 'root',
        group   => 'wikidev',
        mode    => '0775',
        replace => false,
    }
}
