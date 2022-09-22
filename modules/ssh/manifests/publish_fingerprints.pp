# @summary Provisions a directory for publishing SSH fingerprints collected from PuppetDB
# @param document_root the document root to right fingerprints
class ssh::publish_fingerprints (
    Stdlib::Unixpath $document_root,
) {
    $exported_types = ['ecdsa', 'ed25519', 'rsa']
    $ssh_fingerprints = puppetdb::query_facts(['ssh', 'networking'])

    file{"${document_root}/ssh-fingerprints.txt":
        ensure  => file,
        backup  => false,  # Theses files change often don't back them up
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => epp('ssh/publish_fingerprints/ssh-fingerprints.txt',
                      {'ssh_fingerprints' => $ssh_fingerprints}),
    }


    $exported_types.each |String $type| {
        $params = {
            'ssh_fingerprints' => $ssh_fingerprints,
            'types'            => [$type],
        }
        file{"${document_root}/known_hosts.${type}":
            ensure  => file,
            backup  => false,  # Theses files change often don't back them up
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            content => epp('ssh/publish_fingerprints/known_hosts', $params),
        }
    }
}
