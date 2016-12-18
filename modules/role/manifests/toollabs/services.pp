# filtertags: labs-project-tools
class role::toollabs::services(
    $active_host = 'tools-services-01.eqiad.wmflabs',
) {
    system::role { 'role::toollabs::services':
        description => 'Tool Labs manifest based services',
    }

    include role::aptly::server
    # Backup packages!
    # FIXME: Find out if we deserve better than this
    file { '/data/project/.system/aptly':
        ensure => directory,
        owner  => 'root',
        group  => "${::labsproject}.admin",
        mode   => '0770',
    }

    # TODO: It would look nicer not to subscribe to the Execs but the
    # defined type, if the Exec triggers the defined type.  Needs to
    # be tested.
    exec { 'backup_aptly_packages':
        command   => "/usr/bin/rsync --chmod 440 --chown root:${::labsproject}.admin -ilrt /srv/packages/ /data/project/.system/aptly/${::fqdn}",
        subscribe => Exec["publish-aptly-repo-jessie-${::labsproject}",
                          "publish-aptly-repo-precise-${::labsproject}",
                          "publish-aptly-repo-trusty-${::labsproject}"],
        logoutput => true,
    }

    class { '::toollabs::services':
        active => ($::fqdn == $active_host),
    }

    class { '::toollabs::bigbrother':
        active => ($::fqdn == $active_host),
    }

    class { '::toollabs::updatetools':
        active => ($::fqdn == $active_host),
    }

    class { '::toollabs::admin_web_updater':
        active => ($::fqdn == $active_host)
    }
}
