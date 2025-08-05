# SPDX-License-Identifier: Apache-2.0
# This class is designed and tested to run on a cloud-vps VM.
#
# It will create a single-node k3s cluster using files stored
#  in cloud-vps object storage, following the 'air gap install'
#  method described here:
#
#  https://docs.k3s.io/installation/airgap
#
# The k3s binary and install script are stored in object storage
#  in the 'magnum' project under the 'k3s' container.
#
# K3s docker images are stored in the cloudinfra image registry
#  docker-registry.wmcloud.org
#
# When copied into object storage from github, the k3s files
#  should be renamed with a version string so that can be
#  specified in $k3s_version.
#
# The install script itself is unversioned as it seems largely
#  static.
#
class k3s(
    String $k3s_version = 'v1.30.14+k3s2',
    Stdlib::HTTPSUrl $objectstore_base_path = 'https://object.eqiad1.wikimediacloud.org/swift/v1/AUTH_c2c23ceb46404a62a80492b07dac4685/k3s',
    String $k3s_args = '', # for example, '--disable traefik'
) {
    $k3sbinary = "k3s-${k3s_version}"
    $binarylocalpath = '/usr/local/bin/k3s'
    $binarydownloadpath = "${objectstore_base_path}/${k3sbinary}"
    exec { 'download k3s binary':
        creates => $binarylocalpath,
        command => "/usr/bin/wget -O ${binarylocalpath} ${binarydownloadpath}",
    }

    $k3sinstallscript = 'get_k3s.sh'
    $installscriptlocalpath = "/root/${k3sinstallscript}"
    $installscriptdownloadpath = "${objectstore_base_path}/${k3sinstallscript}"
    exec { 'download k3s install script':
        creates => $installscriptlocalpath,
        command => "/usr/bin/wget -O ${installscriptlocalpath} ${installscriptdownloadpath}",
    }

    # Fix ownership/permissions of files after wget
    file { $binarylocalpath:
        require => Exec['download k3s binary'],
        owner   => root,
        group   => root,
        mode    => '0744',
    }
    file { $installscriptlocalpath:
        require => Exec['download k3s install script'],
        owner   => root,
        group   => root,
        mode    => '0744',
    }

    exec { 'install k3s':
        command     => "/usr/bin/bash ${installscriptlocalpath} ${k3s_args}",
        environment => ['INSTALL_K3S_SKIP_DOWNLOAD=true'],
        require     => File[$binarylocalpath, $installscriptlocalpath],
        creates     => '/etc/rancher/k3s/k3s.yaml',
        user        => root,
    }
}
