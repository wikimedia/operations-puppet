class profile::configmaster(
    $conftool_prefix = lookup('conftool_prefix'),
) {

    $vhostnames = [
        'config-master.eqiad.wmnet',
        'config-master.codfw.wmnet',
        'config-master.esams.wmnet',
        'config-master.ulsfo.wmnet',
        'config-master.eqsin.wmnet',
        'config-master.wikimedia.org',
    ]

    $root_dir = '/srv/config-master'

    file { $root_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # The contents of these files are managed by puppet-merge, but user
    # gitpuppet can't/shouldn't be able to create files under $root_dir.
    # So puppet makes sure the file at least exists, and then puppet-merge
    # can write.
    file { "${root_dir}/puppet-sha1.txt":
        ensure => present,
        owner  => 'gitpuppet',
        group  => 'gitpuppet',
        mode   => '0644',
    }

    file { "${root_dir}/labsprivate-sha1.txt":
        ensure => present,
        owner  => 'gitpuppet',
        group  => 'gitpuppet',
        mode   => '0644',
    }

    # Write pybal pools
    class { '::pybal::web':
        ensure   => present,
        root_dir => $root_dir,
        services => wmflib::service::fetch(true),
    }

    httpd::site { 'config-master':
        ensure   => present,
        priority => 50,
        content  => template('profile/configmaster/config-master.conf.erb'),
        notify   => Service['apache2'],
        require  => File[$root_dir],
    }

    ferm::service { 'pybal_conf-http':
        proto  => 'tcp',
        port   => 80,
        srange => '$PRODUCTION_NETWORKS',
    }

    file { '/usr/local/lib/nagios/plugins/disc_desired_state':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => '0555',
        source => 'puppet:///modules/profile/configmaster/disc_desired_state.py',
    }

    nrpe::monitor_service { 'discovery-diffs':
        description    => 'DNS Discovery operations diffs',
        nrpe_command   => '/usr/local/lib/nagios/plugins/disc_desired_state',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/DNS/Discovery#Discrepancy',
        retries        => 2, # We have a spectrum between 4 and 8 hours
        check_interval => 240, # 4h
        retry_interval => 240,
    }
    $ssh_fingerprints = query_facts('', ['ssh'])
    file{"${root_dir}/ssh-fingerprints.txt":
        ensure  => file,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => template('profile/configmaster/ssh-fingerprints.txt.erb')
    }
    ['ecdsa', 'ed25519', 'rsa'].each |String $type| {
        file{"${root_dir}/known_hosts.${type}":
            ensure  => file,
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            content => template('profile/configmaster/known_hosts.erb')
        }
    }
}
