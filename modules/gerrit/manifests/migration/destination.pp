# sets up rsync for a migration of gerrit's git data to a new server
class gerrit::migration::destination {

    $sourceip='208.80.154.80'

    ferm::service { 'gerrit-migration-rsync':
        ensure => absent,
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include rsync::server

    file { '/srv/gerrit/':
        ensure => 'directory',
    }

    rsync::server::module { 'gerrit_git_data':
        ensure      => absent,
        path        => '/srv/gerrit',
        read_only   => 'no',
        hosts_allow => $sourceip,
        require     => File['/srv/gerrit'],
    }
}
