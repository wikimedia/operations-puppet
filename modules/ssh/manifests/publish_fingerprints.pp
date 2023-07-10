# @summary Provisions a directory for publishing SSH fingerprints collected from PuppetDB
# @param document_root the document root to right fingerprints
class ssh::publish_fingerprints (
    Stdlib::Unixpath $document_root,
) {

    file { "${document_root}/known_hosts":
        ensure => link,
        target => '/etc/ssh/ssh_known_hosts',
    }

    file { ["${document_root}/known_hosts.rsa",
            "${document_root}/known_hosts.ed25519",
            "${document_root}/known_hosts.ecdsa",
            "${document_root}/ssh-fingerprints.txt",]:
        ensure  => absent,
    }

}
