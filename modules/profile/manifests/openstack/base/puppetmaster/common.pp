class profile::openstack::base::puppetmaster::common () {
    include profile::openstack::base::puppetmaster::enc_client

    # Update Puppet git repositories
    class { 'puppetmaster::gitsync':
        run_every_minutes => 1,
    }

    ferm::service { 'puppetmaster':
        proto  => 'tcp',
        port   => '8141',
        srange => '$LABS_NETWORKS',
    }

    # Git defaults to preventing multiple users from messing with the
    # a directory, but for us that's a feature more than a security risk.
    #
    # T325128, T325280
    git::systemconfig { 'allow multiple local git users in labs/private':
        settings => {
            'safe' => {
                'directory' => '/var/lib/git/labs/private/',
            }
        }
    }
    git::systemconfig { 'allow multiple local git users in operations/puppet':
        settings => {
            'safe' => {
                'directory' => '/var/lib/git/operations/puppet/',
            }
        }
    }
}
