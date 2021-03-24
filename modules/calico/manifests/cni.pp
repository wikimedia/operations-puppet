# == Class calico::cni
#
# Installs and configure the cni plugins for calico.

class calico::cni(
    Stdlib::Host  $master_fqdn,
    String        $calico_cni_username,
    String        $calico_cni_token,
) {
    require ::calico

    file { ['/etc/cni', '/etc/cni/net.d']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    case $::calico::calico_version {
        '3': {
            # Generate a dedicated kubeconfig for the cni plugin to use
            $kubeconfig = '/etc/cni/net.d/calico-kubeconfig'
            k8s::kubeconfig { $kubeconfig:
                master_host => $master_fqdn,
                username    => $calico_cni_username,
                token       => $calico_cni_token,
            }

            file { '/etc/cni/net.d/10-calico.conflist':
                content => template('calico/cni.conf_v3.erb'),
                owner   => 'root',
                group   => 'root',
                mode    => '0755',
            }
        }
        default: { fail('Unsupported calico version') }
    }

}
