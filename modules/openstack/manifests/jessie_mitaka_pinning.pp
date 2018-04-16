class openstack::jessie_mitaka_pinning {
    if os_version('debian != jessie') {
        fail('Class is meant to be applied only on Debian Jessie')
    }

    apt::pin { 'jessie_mitaka_pinning_oslo':
        package  => 'python-oslo.config python-oslo.i18n python-oslo.serialization python-oslo.utils python3-oslo.config python3-oslo.i18n python3-oslo.serialization python3-oslo.utils',
        pin      => 'release jessie-backports',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_keystoneclients':
        package  => 'python-keystoneauth1 python-keystoneclient python3-keystoneauth1 python3-keystoneclient',
        pin      => 'release jessie-backports',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_baseclients':
        package  => 'python-novaclient python-openstackclient python-openstacksdk python-os-client-config python3-novaclient',
        pin      => 'release jessie-backports',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_extraclients':
        package  => 'python-cinderclient python-designateclient python-glanceclient python3-glanceclient',
        pin      => 'release jessie-backports',
        priority => '1002',
    }
}
