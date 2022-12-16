class openstack::cinder::backup (
    String  $version,
    Boolean $active,
) {
    require "openstack::serverpackages::${version}::${::lsbdistcodename}"
    require "openstack::cinder::config::${version}"

    ensure_packages(['cinder-backup', 'patch'])

    $api_file_to_patch = '/usr/lib/python3/dist-packages/cinder/backup/api.py'
    $api_patch_file = "${api_file_to_patch}.patch"
    file {$api_patch_file:
        source => "puppet:///modules/openstack/${version}/cinder/hacks/backup/api.py.patch",
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
    exec { "apply ${api_patch_file}":
        command => "/usr/bin/patch --forward ${api_file_to_patch} ${api_patch_file}",
        unless  => "/usr/bin/patch --reverse --dry-run -f ${api_file_to_patch} ${api_patch_file}",
        require => [File[$api_patch_file], Package['cinder-backup']],
        notify  => Service['cinder-backup'],
    }

    service { 'cinder-backup':
        ensure    => $active,
        subscribe => Class["openstack::cinder::config::${version}"],
    }
}
