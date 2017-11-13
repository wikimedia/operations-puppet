# == Define cergen::certificate
# == Parameters
# arguments
#
define cergen::certificate (
    $destination,
    $manifest,
    # TODO: use ensure
    $ensure              = 'present',
    $owner               = 'root',
    $group               = 'root',
    $include_private_key = false,
) {
    include ::passwords::certificates
    $password = $::passwords::certificates::certificates[$title]

    $defaults = {
        'authority' =>  'puppet_ca',
        'subject' => {
            'country_name' => 'US',
            'state_or_province_name' => 'CA',
            'locality_name' => 'San Francisco',
            'organization_name' => 'Wikimedia Foundation',
        },
        'expiry' => 'null',
        'key' => {
            'algorithm' => 'ec',
            'password' => $password,
        }
    }
    $certificate_manifest = deep_merge($manifest, $defaults)

    @@cergen::manifest { $title:
        ensure  => $ensure,
        content => template('cergen/certificate.yaml.erb'),
    }

    # TODO: automatically run cergen --generate using puppet generate() function?!

    # TODO: Assuming the file is on the puppet master, now render it?
    # Or, should this be a separate define?

    # base-path: /etc/puppet/private/modules/secret/files/certificates/certs/$name/
    # base-private-path: /etc/puppet/private/modules/secret/secrets/certficates/private/$name/

    # Default subsequent file resources with these.
    File {
        owner => $owner,
        group => $group,
        mode  => '0400',
    }

    file { $destination:
        ensure  => 'directory',
        mode    => '0555',
        # Puppet will fully manage this directory.  Any files in
        # this directory that are not managed by puppet will be deleted.
        recurse => true,
        purge   => true,
    }

    file { "${destination}":
        ensure  => 'directory',
        mode    => '0555',
        # Puppet will fully manage this directory.  Any files in
        # this directory that are not managed by puppet will be deleted.
        recurse => true,
        purge   => true,
        source  => "puppet:///secret/certificates/certs/${title}"
    }

    if $include_private_key {
        file { "${destination}/{title}.key.private.pem":
            ensure  => 'directory',
            content => secret("certificates/private/${title}/${title}.key.private.pem"),
        }
    }
}
