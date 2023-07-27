# @summary Provisions a directory for publishing SSH fingerprints collected from PuppetDB
# @param document_root the document root to right fingerprints
class ssh::publish_fingerprints (
    Stdlib::Unixpath $document_root,
) {

    # known_hosts.ecdsa is gkept around as an old version of the wmf-update-know-hosts script
    # fetched that file
    $known_hosts = ssh::known_hosts(false)

    file { "${document_root}/known_hosts":
        ensure  => file,
        backup  => false,
        content => template('ssh/known_hosts.erb'),
    }
    file {"${document_root}/known_hosts.ecdsa":
        ensure => link,
        target => "${document_root}/known_hosts",
    }
}
