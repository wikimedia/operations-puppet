# List of available backup filesets
class profile::backup::filesets() {
    # This has been taken straight from old files/backup/disklist-*
    bacula::director::fileset { 'root':
        includes     => [ '/' ]
    }
    bacula::director::fileset { 'cloudweb-srv-backup':
        includes => [ '/srv/backup' ]
    }
    # TODO: remove this when geowiki site is no longer needed.
    # https://phabricator.wikimedia.org/T190059
    bacula::director::fileset { 'a-geowiki-data-private-bare':
        includes => [ '/srv/geowiki/data-private-bare' ]
    }
    bacula::director::fileset { 'home':
        includes => [ '/home' ]
    }
    bacula::director::fileset { 'roothome':
        includes => [ '/root' ]
    }
    bacula::director::fileset { 'srv-autoinstall':
        includes => [ '/srv/autoinstall' ]
    }
    bacula::director::fileset { 'srv-tftpboot':
        includes => [ '/srv/tftpboot' ]
    }
    bacula::director::fileset { 'srv-wikimedia':
        includes => [ '/srv/wikimedia' ]
    }
    bacula::director::fileset { 'srv-org-wikimedia':
        includes => [ '/srv/org/wikimedia' ]
    }
    bacula::director::fileset { 'srv-docroot-org-wikimedia-doc':
        includes => [ '/srv/docroot/org/wikimedia/doc' ]
    }
    bacula::director::fileset { 'var-lib-archiva':
        includes     => [ '/var/lib/archiva' ],
    }
    bacula::director::fileset { 'var-lib-jenkins-config':
        includes     => [ '/var/lib/jenkins/config.xml' ],
    }
    bacula::director::fileset { 'srv-gerrit-git':
        includes => [ '/srv/gerrit/git' ]
    }
    bacula::director::fileset { 'var-lib-carbon-whisper-coal':
        includes => [ '/var/lib/carbon/whisper/coal' ]
    }
    bacula::director::fileset { 'var-lib-graphite-web-graphite-db':
        includes => [ '/var/lib/graphite-web/graphite.db' ]
    }
    bacula::director::fileset { 'var-lib-jenkins-backups':
        includes => [ '/var/lib/jenkins/backups' ]
    }
    bacula::director::fileset { 'var-lib-mailman':
        includes => [ '/var/lib/mailman' ]
    }
    bacula::director::fileset { 'var-lib-puppet-ssl':
        includes => [ '/var/lib/puppet/ssl', '/var/lib/puppet/server/ssl' ]
    }
    bacula::director::fileset { 'var-lib-puppet-volatile':
        includes => [ '/var/lib/puppet/volatile' ]
    }
    bacula::director::fileset { 'var-opendj-backups':
        includes => [ '/var/opendj/backups' ]
    }
    bacula::director::fileset { 'var-vmail':
        includes => [ '/var/vmail' ]
    }
    bacula::director::fileset { 'mysql-srv-backups':
        includes => [ '/srv/backups' ]
    }
    bacula::director::fileset { 'krb-srv-backup':
        includes => [ '/srv/backup' ]
    }
    bacula::director::fileset { 'mysql-srv-backups-dumps-latest':
        includes => [ '/srv/backups/dumps/latest' ]
    }
    bacula::director::fileset { 'bugzilla-static':
        includes => [ '/srv/org/wikimedia/static-bugzilla' ]
    }
    bacula::director::fileset { 'rt-static':
        includes => [ '/srv/org/wikimedia/static-rt' ]
    }
    bacula::director::fileset { 'srv-deployment':
        includes => [ '/srv' ]
    }
    bacula::director::fileset { 'mysql-bpipe-xfalse-pfalse-ifalse':
        includes => [],
        plugins  => [ 'mysql-bpipe-xfalse-pfalse-ifalse',]
    }
    bacula::director::fileset { 'mysql-bpipe-xfalse-pfalse-itrue':
        includes => [],
        plugins  => [ 'mysql-bpipe-xfalse-pfalse-itrue',]
    }
    bacula::director::fileset { 'mysql-bpipe-xfalse-ptrue-ifalse':
        includes => [],
        plugins  => [ 'mysql-bpipe-xfalse-ptrue-ifalse',]
    }
    bacula::director::fileset { 'mysql-bpipe-xfalse-ptrue-itrue':
        includes => [],
        plugins  => [ 'mysql-bpipe-xfalse-ptrue-itrue',]
    }
    bacula::director::fileset { 'mysql-bpipe-xtrue-pfalse-ifalse':
        includes => [],
        plugins  => [ 'mysql-bpipe-xtrue-pfalse-ifalse',]
    }
    bacula::director::fileset { 'mysql-bpipe-xtrue-pfalse-itrue':
        includes => [],
        plugins  => [ 'mysql-bpipe-xtrue-pfalse-itrue',]
    }
    bacula::director::fileset { 'mysql-bpipe-xtrue-ptrue-ifalse':
        includes => [],
        plugins  => [ 'mysql-bpipe-xtrue-ptrue-ifalse',]
    }
    bacula::director::fileset { 'mysql-bpipe-xtrue-ptrue-itrue':
        includes => [],
        plugins  => [ 'mysql-bpipe-xtrue-ptrue-itrue',]
    }
    bacula::director::fileset { 'bpipe-mysql-xfalse-ptrue-itrue':
        includes => [],
        plugins  => [ 'bpipe-mysql-xfalse-ptrue-itrue'],
    }
    bacula::director::fileset { 'var-lib-grafana':
        includes => [ '/var/lib/grafana' ],
    }
    bacula::director::fileset { 'srv-repos':
        includes => [ '/srv/repos' ],
    }
    bacula::director::fileset { 'yubiauth-aeads':
        includes => [ '/var/cache/yubikey-ksm/aeads' ],
    }
    bacula::director::fileset { 'openldap':
        includes => [ '/var/run/openldap-backup' ],
    }
    bacula::director::fileset { 'contint':
        includes => [ '/srv', '/var/lib/zuul', '/var/lib/jenkins' ],
        excludes => [ '/srv/jenkins/builds', '/var/lib/jenkins/builds', ],
    }
    bacula::director::fileset { 'etcd':
        includes => [ '/srv/backups/etcd' ]
    }

    bacula::director::fileset { 'librenms':
        includes => [ '/var/lib/librenms', '/srv/librenms' ]
    }

    bacula::director::fileset { 'smokeping':
        includes => [ '/var/lib/smokeping', '/var/cache/smokeping' ]
    }

    bacula::director::fileset { 'rancid':
        includes => [ '/var/lib/rancid' ]
    }

    bacula::director::fileset { 'hadoop-namenode-backup':
        includes => [ '/srv/backup/hadoop/namenode' ]
    }

    bacula::director::fileset { 'postgresql':
        includes => [ '/srv/postgres-backup/' ]
    }

    bacula::director::fileset { 'netbox':
        includes => [ '/srv/netbox-dumps/',
                    ]
    }

    bacula::director::fileset { 'netbox-postgres':
        includes => [ '/srv/postgres-backup/',
                    ]
    }

    bacula::director::fileset { 'arclamp-application-data':
        includes => [ '/srv/xenon/' ]
    }

    bacula::director::fileset { 'analytics-meta-mysql-lvm-backup':
        includes => [ '/srv/backup/mysql/analytics-meta' ]
    }

    bacula::director::fileset { 'idp':
        includes => [ '/srv/cas/devices' ]
    }
}
