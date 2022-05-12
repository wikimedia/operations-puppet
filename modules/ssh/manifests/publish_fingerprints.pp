# @summary Provisions a directory for publishing SSH fingerprints collected from PuppetDB
# @param document_root the document root to right fingerprints
class ssh::publish_fingerprints (
    Stdlib::Unixpath $document_root,
) {
    $ssh_fingerprints = puppetdb::query_facts(['ssh', 'networking'])

    file{"${document_root}/ssh-fingerprints.txt":
        ensure  => file,
        backup  => false,  # Theses files change often don't back them up
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => template('ssh/publish_fingerprints/ssh-fingerprints.txt.erb'),
    }

    ['ecdsa', 'ed25519', 'rsa'].each |String $type| {
        file{"${document_root}/known_hosts.${type}":
            ensure  => file,
            backup  => false,  # Theses files change often don't back them up
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            content => template('ssh/publish_fingerprints/known_hosts.erb'),
        }
    }
}
