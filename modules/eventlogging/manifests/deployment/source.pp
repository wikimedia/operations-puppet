# == Class eventlogging::deployment::source
# Include this class on a scap3 deployment server,
# e.g. tin, deployment-tin, etc.
# It sets up private keys and adds them to keyholder,
# allowing certain groups to deploy via ssh using
# the configured ssh key for the deploy user.
#
class eventlogging::deployment::source {
    require ::keyholder
    require ::keyholder::monitoring

    $key_fingerprint = $::realm ? {
        'labs'       => $::labsproject ? {
            'deployment-prep' => '02:9b:99:e2:f0:16:70:a3:d2:5a:e6:02:a3:73:0e:b0',
            default           => undef,
        },
        'production' => 'b6:4e:1a:1b:4b:70:ef:91:31:cd:a3:18:9a:ca:41:44',
        default      => undef,
    }

    if !$key_fingerprint {
        fail('Could not determine keyholder key_fingerprint for scap when setting up eventlogging deployment source for eventlogging.')
    }

    # Use eventlogging-admins group for deployment in production,
    # and just the current labs project group in labs.
    $trusted_group = $::realm ? {
        'labs'  => "project-${::labsproject}",
        default => 'eventlogging-admins',
    }

    # For betalabs/deployment-prep, the eventlogging private key has been
    # added to deployment-puppetmaster:/var/lib/git/private/labs/files/ssh/tin.
    keyholder::agent { 'eventlogging':
        trusted_group   => $trusted_group,
        key_fingerprint => $key_fingerprint,
        key_file        => 'eventlogging_rsa',
    }
}
