# SPDX-License-Identifier: Apache-2.0
# Class: profile::netbox::scripts
#
# This profile configures a small proxy for retrieving results from Netbox CustomScripts
#
# Actions:
#       Setup uwsgi-netbox-scriptproxy as a proxy.
#       Create an apache site with limited access to proxy to the above.
#
# Requires:
#
# Sample Usage:
#       include profile::netbox::scripts
#
class profile::netbox::scripts {

    include profile::netbox
    $ssl_paths = $profile::netbox::ssl_paths
    $uwsgi_environ=[
        'LANG=C.UTF-8',
        'PYTHONENCODING=utf-8',
    ]
    $venv_path = '/srv/deployment/netbox/venv'
    $script_path = '/srv/deployment/netbox-extras/tools/custom_script_proxy.py'
    $service_port=8002
    $apache_port=8443

    service::uwsgi { 'netbox-scriptproxy':
        port            => $service_port,
        deployment_user => 'netbox',
        deployment      => '',
        config          => {
            need-plugins => 'python3',
            venv         => $venv_path,
            wsgi-file    => $script_path,
            vacuum       => true,
            http-socket  => "127.0.0.1:${service_port}",
            # T170189: make sure Python has a sane default encoding
            env          => $uwsgi_environ,
            max-requests => 300,
        },
        icinga_check    => false,
        core_limit      => '30G',
        require         => [
            Scap::Target[$profile::netbox::scap_repo],
            Git::Clone['operations/software/netbox-extras']
        ],
    }

    profile::auto_restarts::service { 'uwsgi-netbox-scriptproxy': }

    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)

    $ferm_nodes = wmflib::role::hosts('cluster::management').sort.join(' ')

    ferm::service { 'netbox_scripts_https':
        proto  => 'tcp',
        port   => $apache_port,
        desc   => 'Semi-restricted access to Netbox script proxy',
        srange => "(@resolve((${ferm_nodes})) @resolve((${ferm_nodes}), AAAA))",
    }

    httpd::site { $facts['networking']['fqdn']:
        content => template('profile/netbox/netbox-scripts.erb'),
    }

}
