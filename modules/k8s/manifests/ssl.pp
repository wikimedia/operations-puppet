# Copy of etcd::ssl
# Copies appropriate cert files from the puppet CA infrastructure
# To be usable by the k8s binaries
# Note: Only copies public components, no private keys
class k8s::ssl(
    $provide_private = false,
    $user = 'root',
    $group = 'root',
    $ssldir = '/var/lib/puppet/ssl',
    $target_basedir = '/var/lib/kubernetes'
) {
    ::sslcert::expose_puppet_certs { $target_basedir:
        provide_private => $provide_private,
        user            => $user,
        group           => $group,
        ssldir          => $ssldir,
    }
}
