class mediawiki::scap {
    include ::mediawiki::users

    $mediawiki_deployment_dir = '/srv/mediawiki'
    $mediawiki_staging_dir    = '/srv/mediawiki-staging'

    package { 'scap':
        ensure   => latest,
        provider => 'trebuchet',
    }

    file { $mediawiki_deployment_dir:
        ensure  => directory,
        owner   => 'mwdeploy',
        group   => 'mwdeploy',
        mode    => '0775',
    }

    file { '/etc/profile.d/mediawiki.sh':
        content => template('mediawiki/mediawiki.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
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
        creates => "${mediawiki_deployment_dir}/wmf-config/InitialiseSettings.php",
        timeout => 30 * 60,  # 30 minutes
    }
}
