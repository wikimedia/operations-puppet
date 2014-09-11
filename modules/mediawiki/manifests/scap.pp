class mediawiki::scap {
    include ::misc::deployment::vars
    include ::mediawiki::users

    package { 'scap':
        ensure   => latest,
        provider => 'trebuchet',
    }

    file { '/srv/mediawiki':
        ensure  => directory,
        owner   => 'mwdeploy',
        group   => 'mwdeploy',
        mode    => '0775',
    }

    file { '/etc/profile.d/add_scap_to_path.sh':
        source => 'puppet:///modules/mediawiki/profile.d_add_scap_to_path.sh',
    }

    # These get invoked by scap over SSH using a non-interactive, non-login
    # shell and thus won't pick up the /etc/profile.d script declared above.
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
        creates => '/srv/mediawiki/wmf-config/InitialiseSettings.php',
        timeout => 30 * 60,  # 30 minutes
    }
}
