# SPDX-License-Identifier: Apache-2.0

# Common tasks to be done only once per mediabackup host:
# install the software, create the user and set the initscripts
# Parameters:
# * user: User to be created, which will own the files and run the service
# * home_dir: Default dir of the above user

class versitygw::storage_common (
    String $unix_user            = 'objectstorage',
    String $unix_group           = 'objectstorage',
    Stdlib::Unixpath $config_dir = '/etc/versitygw',
    Stdlib::Unixpath $home_dir   = '/srv',
){
    # TODO: Build deb package # ensure_packages(['versitygw', ])

    systemd::sysuser { $unix_user:
        home_dir => $home_dir,
    }

    file { $config_dir:
        ensure => directory,
        mode   => '0755',
    }

    file { "${config_dir}/ssl":
        ensure  => directory,
        mode    => '0700',
        owner   => $unix_user,
        group   => $unix_group,
        require => [ File[$config_dir], User[$unix_user] ],
    }

    file { "${home_dir}/iam":
        ensure => directory,
        mode   => '0700',
        owner  => $unix_user,
        group  => $unix_group,
    }
}
