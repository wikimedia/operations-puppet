# == Class phabricator::deployment::source
# Include this class on a scap3 deployment server,
# e.g. tin, deployment-bastion, etc.
# It sets up private keys and adds them to keyholder,
# allowing certain groups to deploy via ssh using
# the configured ssh key for the deploy user.
#
class phabricator::deployment::source {
    require ::keyholder
    require ::keyholder::monitoring

    $key_fingerprint = $::realm ? {
        'labs'       => $::labsproject ? {
            'phabricator' => '36:75:c2:fa:34:02:c8:8c:ff:30:09:aa:f7:77:96:41',
            default           => undef,
        },
        'production' => '39:b3:2c:a7:b2:80:65:ff:0c:97:e1:22:88:6c:59:10',
        default      => undef,
    }

    if !$key_fingerprint {
        fail('Could not determine keyholder key_fingerprint for scap when setting up deployment source for phabricator.')
    }

    # Use phabricator-admins group for deployment in production,
    # and just the current labs project group in labs.
    $trusted_group = $::realm ? {
        'labs'  => "project-${::labsproject}",
        default => 'phabricator-roots',
    }

    keyholder::agent { 'phabricator':
        trusted_group   => $trusted_group,
        key_fingerprint => $key_fingerprint,
        key_content     => secret('phabricator/phab_deploy_private_key'),
    }
}

