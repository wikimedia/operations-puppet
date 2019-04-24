# this is the class for use by VM instances in Cloud VPS. Don't use for HW servers
class openstack::clientpackages::vms::mitaka::jessie(
) {
    requires_realm('labs')
    require openstack::commonpackages::mitaka

    apt::pin { 'jessie_mitaka_pinning_python_cinderclient':
        package  => 'python-cinderclient',
        pin      => 'version 1:1.6.0-3~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python_designateclient':
        package  => 'python-designateclient',
        pin      => 'version 2.1.0-2~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python_glanceclient':
        package  => 'python-glanceclient',
        pin      => 'version 1:2.0.0-3~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python_keystoneauth1':
        package  => 'python-keystoneauth1',
        pin      => 'version 2.4.1-1~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python_keystoneclient':
        package  => 'python-keystoneclient',
        pin      => 'version 1:2.3.1-3~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python_novaclient':
        package  => 'python-novaclient',
        pin      => 'version 2:3.3.1-3~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python_openstackclient':
        package  => 'python-openstackclient',
        pin      => 'version 2.3.0-3~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python_openstacksdk':
        package  => 'python-openstacksdk',
        pin      => 'version 0.8.1-3~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python_os_client_config':
        package  => 'python-os-client-config',
        pin      => 'version 1.16.0-1~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python_oslo_config':
        package  => 'python-oslo.config',
        pin      => 'version 1:3.9.0-4~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python_oslo_i18n':
        package  => 'python-oslo.i18n',
        pin      => 'version 3.5.0-3~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python_oslo_serialization':
        package  => 'python-oslo.serialization',
        pin      => 'version 2.4.0-3~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python_oslo_utils':
        package  => 'python-oslo.utils',
        pin      => 'version 3.8.0-3~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python3_glanceclient':
        package  => 'python3-glanceclient',
        pin      => 'version 1:2.0.0-3~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python3_keystoneauth1':
        package  => 'python3-keystoneauth1',
        pin      => 'version 2.4.1-1~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python3_keystoneclient':
        package  => 'python3-keystoneclient',
        pin      => 'version 1:2.3.1-3~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python3_novaclient':
        package  => 'python3-novaclient',
        pin      => 'version 2:3.3.1-3~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python3_oslo_config':
        package  => 'python3-oslo.config',
        pin      => 'version 1:3.9.0-4~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python3_oslo_i18n':
        package  => 'python3-oslo.i18n',
        pin      => 'version 3.5.0-3~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python3_oslo_serialization':
        package  => 'python3-oslo.serialization',
        pin      => 'version 2.4.0-3~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_python3_oslo_utils':
        package  => 'python3-oslo.utils',
        pin      => 'version 3.8.0-3~bpo8+1',
        priority => '1002',
    }

    apt::pin { 'jessie_mitaka_pinning_nova_common':
        package  => 'nova-common',
        pin      => 'version 2:13.1.0-2~bpo8+1',
        priority => '1002',
    }
}
