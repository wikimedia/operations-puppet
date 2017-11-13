# == Define cergen::certificate
##
# Declare and exported cergen::manifest with $properties and $defaults,
# and expect that that exported cergen::manifest is used to render
# a cergen manifest.certs.yaml file in /etc/cergen/manifests.d on a puppetmaster.
# Also expect cergen --generate to be run on the puppetmaster so, that
# certificate files are in:
#   modules/$source_module_name/files/certs/$title/
#
# and private key files are in:
#   modules/$source_module_name/secrets/certs/$title/
#
# These files will then be copied to the declaring node into $destination/
#
# == Usage
#
# # Render /etc/cergen/manifest.d/eqiad_kafka_broker_kafka-jumbo1001.yaml on the puppetmaster,
# # run cergen --generate /etc/cergen/manifest.d/eqiad_kafka_broker_kafka-jumbo1001.yaml
# cergen::cergificate { 'jumbo-eqiad_kafka_broker_kafka-jumbo1001':
#   destination => '/etc/kafka/certificates',
#   properties  => {
#       'authority' => 'other_ca',
#       'key' => {
#           'algorithm' => 'rsa'
#       }
#   },
# }
#
# You must also have a key password set in the passwords::certificates class in
# the $certificates[$title] = 'mypassword' variable.
#
# == Parameters
#
# [*destination*]
#   Directory path in which certificate files should be copied.
#
# [*properties*]
#   cergen manifest properties for this certificate.  There are sane defaults provided.
#
# [*include_private_key*]
#   If true, the private key file will also be copied.  Default: false
#
# [*source_module_name*]
#   Name of puppet module which certificate files are located.  Default: 'certificates'
#
# [*ensure*]
#
# [*owner*]
#
# [*group*]
#
define cergen::certificate (
    $destination,
    $properties          = {},
    # TODO: use ensure
    $ensure              = 'present',
    $owner               = 'root',
    $group               = 'root',
    $include_private_key = false,
    $source_module_name  = 'certificates',
) {
    # Pull key password out of $passwords::certificates::certificates
    include ::passwords::certificates
    $password = $::passwords::certificates::certificates[$title]

    # Location where files will be generated on the
    # host that realizes the exported cergen::manifests.
    $path         = "/etc/puppet/private/modules/${source_module_name}/files/certs/${title}"
    $private_path = "/etc/puppet/private/modules/${source_module_name}/secrets/certs/${title}"

    $defaults = {
        'authority'    =>  'puppet_ca',
        'path'         => $path,
        'private_path' => $private_path,
        'subject'      => {
            'country_name'           => 'US',
            'state_or_province_name' => 'CA',
            'locality_name'          => 'San Francisco',
            'organization_name'      => 'Wikimedia Foundation',
        },
        'expiry'       => 'null',
        'key'          => {
            'algorithm' => 'ec',
            'password'  => $password,
        }
    }
    $certificate_manifest = {
        "${title}" => deep_merge($defaults, $properties)
    }

    # Export cergen::manifest, this should be realized on the puppetmaster.
    @@cergen::manifest { $title:
        ensure  => $ensure,
        content => template('cergen/certificate.yaml.erb'),
    }

    # generate() will run this command on the puppetmaster.  If this works, this will run
    # cergen --generate if the certificate files haven't been generated, and they will
    # be available for sourcing below.
    # TODO: also auto commit to puppet private??? Probably have to.
    generate("/usr/bin/test -e ${::cergen::manifests_path}/${title}.certs.yaml && /usr/bin/test -d ${path} || /usr/bin/cergen --generate --certificates ${title} ${::cergen::manifests_path}")

    # Copy all public certificate files.
    file { $destination:
        ensure  => 'directory',
        owner   => $owner,
        group   => $group,
        mode    => '0555',
        # Puppet will fully manage this directory.  Any files in
        # this directory that are not managed by puppet will be deleted.
        recurse => true,
        purge   => true,
        source  => "puppet:///modules/${source_module_name}/certs/${title}"
    }

    if $include_private_key {
        # Also copy secret private key file using secrets() function.
        file { "${destination}/{title}.key.private.pem":
            mode    => '0400',
            owner   => $owner,
            group   => $group,
            content => secret("certs/${title}/${title}.key.private.pem", $source_module_name),
        }
    }
}
