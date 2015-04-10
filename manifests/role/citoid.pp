# vim: set ts=4 et sw=4:
class role::citoid {

    system::role { 'role::citoid': }

    ferm::service { 'citoid':
        proto => 'tcp',
        port  => '1970',
    }

    $zotero_host = hiera('citoid::zotero_host')
    $zotero_port = hiera('citoid::zotero_port')

    service::node { 'citoid':
        port   => 1970,
        config => template('service/node/citoid/config.yaml.erb'),
    }

}
