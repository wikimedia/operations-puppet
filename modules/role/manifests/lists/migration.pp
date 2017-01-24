# sets up rsync for a migration of a
# mailman installation to a new server
class role::lists::migration {

    $sourceip='208.80.154.61'

    ferm::service { 'mailman-http':
        proto => 'tcp',
        port  => '80',
    }

    ferm::service { 'mailman-migration-rsync':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include rsync::server

    rsync::server::module { 'lists':
        path        => '/var/lib/mailman/lists',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    rsync::server::module { 'archives':
        path        => '/var/lib/mailman/archives',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    rsync::server::module { 'data':
        path        => '/var/lib/mailman/data',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    rsync::server::module { 'qfiles':
        path        => '/var/lib/mailman/qfiles',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    rsync::server::module { 'exim':
        path        => '/var/spool/exim4',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    package { 'mailman':
        ensure => 'present',
    }

    service { 'mailman':
        ensure => 'stopped',
    }

    include mailman::scripts

}
