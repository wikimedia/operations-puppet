class mediawiki::sync {
    include ::misc::deployment::vars
    include ::mediawiki::users

    deployment::target { 'scap': }

    file { '/usr/local/bin/mwversionsinuse':
        ensure => link,
        target => '/srv/deployment/scap/scap/bin/mwversionsinuse',
    }

    file { '/usr/local/bin/scap-rebuild-cdbs':
        ensure => link,
        target => '/srv/deployment/scap/scap/bin/scap-rebuild-cdbs',
    }

    file { '/usr/local/bin/scap-recompile':
        ensure => link,
        target => '/srv/deployment/scap/scap/bin/scap-recompile',
    }

    file { '/usr/local/bin/sync-common':
        ensure => link,
        target => '/srv/deployment/scap/scap/bin/sync-common',
    }

    file { '/usr/local/bin/refreshCdbJsonFiles':
        ensure => link,
        target => '/srv/deployment/scap/scap/bin/refreshCdbJsonFiles',
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

    file { '/var/log/mediawiki':
        ensure => directory,
        owner  => 'apache',
        group  => 'wikidev',
        mode   => '0644',
    }

    exec { 'mw-sync':
        command     => '/usr/local/bin/sync-common',
        require     => File['/a/common'],
        user        => 'root',
        group       => 'root',
        refreshonly => true,
        timeout     => 600,
        logoutput   => 'on_failure',
    }

    exec { 'mw-sync-rebuild-cdbs':
        command     => '/usr/local/bin/scap-rebuild-cdbs',
        subscribe   => Exec['mw-sync'],
        user        => 'mwdeploy',
        group       => 'mwdeploy',
        refreshonly => true,
        timeout     => 600,
        logoutput   => 'on_failure',
    }
}
