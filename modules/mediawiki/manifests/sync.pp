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

    exec { 'bootstrap_mediawiki':
        command     => template('mediawiki/bootstrap.command.erb'),
        creates     => '/run/completed-sync',
        user        => 'mwdeploy',
        group       => 'mwdeploy',
        timeout     => 1200,
        require     => File['/a/common'],
    }
}
