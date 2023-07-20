# @summary Provisions a directory for publishing SSH fingerprints collected from PuppetDB
# @param document_root the document root to right fingerprints
class ssh::publish_fingerprints (
    Stdlib::Unixpath $document_root,
) {

    # TODO: update wmf-update-know-host to just fetch the known_host file (not the known_hosts.ecdsa
    file { ["${document_root}/known_hosts", "${document_root}/known_hosts.ecdsa"]:
        ensure => link,
        target => '/etc/ssh/ssh_known_hosts',
    }
}
