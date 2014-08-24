class mediawiki::sync {
    include ::misc::deployment::vars
    include ::mediawiki::users

    package { 'scap':
        ensure   => latest,
        provider => 'trebuchet',
    }

    file { '/etc/profile.d/add_scap_to_path.sh':
        source => 'puppet:///modules/mediawiki/profile.d_add_scap_to_path.sh',
    }

    # (╯°□°）╯︵ ┻━┻

    file { '/usr/local/apache':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        replace => false,
    }

    file { '/usr/local/apache/common-local':
        ensure => directory,
        owner  => 'mwdeploy',
        group  => 'mwdeploy',
        mode   => '0775',
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

    # these get invoked by scap over SSH using a non-interactive, non-login
    # shell thus won't pick up /etc/profile.d above
    file { '/usr/local/bin/scap-rebuild-cdbs':
        ensure  => link,
        target  => '/srv/deployment/scap/scap/bin/scap-rebuild-cdbs',
        require => Package['scap'],
    }

    file { '/usr/local/bin/sync-common':
        ensure  => link,
        target  => '/srv/deployment/scap/scap/bin/sync-common',
        require => Package['scap'],
    }

    exec { '/usr/local/bin/sync-common':
        creates => '/usr/local/apache/common/wmf-config/InitialiseSettings.php',
        timeout => 30 * 60,  # 30 minutes
    }
}
