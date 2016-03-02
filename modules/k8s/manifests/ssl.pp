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
    $ca_cert_path = '/etc/ssl/certs/Puppet_Internal_CA.pem' #TODO: check if this is the correct cert (also for labs)
    $server_cert_path = "${target_basedir}/ssl/cert.pem"
    $server_private_key_path = "${target_basedir}/ssl/server.key"

    ::base::expose_puppet_certs { $target_basedir:
        provide_private => $provide_private,
        user            => $user,
        group           => $group,
        ssldir          => $ssldir,
    }
}
