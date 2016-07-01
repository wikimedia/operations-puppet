# sets up rsync for a migration of gerrit's git data to a new server
class role::gerrit::migration::destination {

    $sourceip='208.80.154.80'

    ferm::service { 'gerrit-migration-rysnc':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include rsync::server

    rsync::server::module { 'gerrit_git_data':
        path        => '/var/lib/gerrit2/review_site/git',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }
}

class role::gerrit::migration::source {
    $cmd = '/usr/bin/rsync -rlpt rsync://lead::gerrit_git_data /var/lib/gerrit2/review_site/git'
    cron { 'rsync_gerrit_data':
        command => $cmd,
        user    => 'root',
        hour    => [0, 6, 12, 18]
    }
}
