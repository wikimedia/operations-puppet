# SPDX-License-Identifier: Apache-2.0
#
# Create a capi worker node for OpenStack Magnum.
#
# Installs k3s, helm, and capi
class profile::openstack::capi(
) {
    class { '::k3s':
        k3s_args => '--disable traefik',
    }

    class { '::helm':
        helm_user_group => root,
        repositories    => {
            'magnum' => 'https://object.eqiad1.wikimediacloud.org/swift/v1/AUTH_c2c23ceb46404a62a80492b07dac4685/helmcharts',
        },
    }

    class { '::openstack::capihelm::service':
        require => [Exec['install k3s'], Class['helm']],
    }
}
