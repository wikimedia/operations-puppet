# sets up rsync for a migration of gerrit's git data to a new server
class gerrit::migration::destination {

    $sourceip='208.80.154.80'

    ferm::service { 'gerrit-migration-rysnc':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include rsync::server

    file { [ '/var/lib/gerrit2/', '/var/lib/gerrit2/review_site',
             '/var/lib/gerrit2/review_site/git' ]:
        ensure => 'directory',
    }

    rsync::server::module { 'gerrit_git_data':
        path        => '/var/lib/gerrit2/review_site/git',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }
}

