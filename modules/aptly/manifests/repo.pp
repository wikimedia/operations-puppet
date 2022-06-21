# SPDX-License-Identifier: Apache-2.0
define aptly::repo (
    $distribution = $title,
    $component = 'main',
    $publish = false,
    $user = 'root',
) {
    require ::aptly

    exec { "create-aptly-repo-${title}":
        command => "/usr/bin/aptly repo create -component=${component} -distribution=${distribution} ${title}",
        unless  => "/usr/bin/aptly repo show ${title} > /dev/null",
        user    => $user,
        cwd     => '/',
    }

    if $publish {
        # Pubish the repo directly, without snapshots
        # This isn't reccomended by aptly for production uses, but is perfect for labs :D
        exec { "publish-aptly-repo-${title}":
            command => "/usr/bin/aptly -architectures=amd64,all -skip-signing -origin=Wikimedia -label='${title}' -distribution='${title}'  -component='${component}' publish repo ${title}",
            unless  => "/usr/bin/aptly publish list | /bin/grep -F '[${title}]' > /dev/null",
            user    => $user,
            cwd     => '/',
            require => Exec["create-aptly-repo-${title}"],
        }
    }
}
