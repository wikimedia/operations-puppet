# SPDX-License-Identifier: Apache-2.0
# @summary make the WMCS-owned production hosts reachable by the cloudcumin masters.
class profile::cumin::cloud_target(
    Array[Stdlib::IP::Address] $cloud_cumin_masters = lookup('cloud_cumin_masters', {'default_value' => []}),
) {
    if !empty($cloud_cumin_masters) {
        $ssh_authorized_sources = join($cloud_cumin_masters, ',')
        $cumin_master_pub_key = secret('keyholder/cloud_cumin_master.pub')

        ssh::userkey { 'cloud-cumin':
            ensure  => present,
            user    => 'root',
            skey    => 'cloud_cumin',
            content => template('profile/cumin/userkey.erb'),
        }

        firewall::service { 'ssh-from-cloudcumin-masters':
          proto  => 'tcp',
          port   => 22,
          srange => $cloud_cumin_masters,
        }
    }
}
