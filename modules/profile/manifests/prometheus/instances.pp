# SPDX-License-Identifier: Apache-2.0
# Instantiate all prometheus instances for this host

class profile::prometheus::instances (
    $instances_cleanup = lookup('prometheus::instances_cleanup', {'default_value' => {}}),
) {
    # On LVM systems, ensure that this host's instances filesystems are provisioned
    # Said provisioning is done by prometheus-provision-fs and the user is prompted to run it.
    # We could let Puppet do the provisioning, but we generally refrain from
    # automated LVM/FS operations in production.
    if ! $facts['lvm_support'] {
        $lvs_to_create = []
    } else {
        $lvs_to_create = prometheus::instances().map |$instance, $config| {
            $lv_name = "prometheus-${instance}"
            $lv_size = $config['provision_lv_size']
            if $facts['networking']['fqdn'] in $config['hosts']
                and ! $facts['logical_volumes'][$lv_name] {
                "prometheus-provision-fs ${instance} ${lv_size}"
            } else {
              []
            }
        }.flatten
    }

    if ! empty($lvs_to_create) {
        $lvs_msg = $lvs_to_create.join("\n")
        fail("Prometheus filesystems are missing, provision with:\n\n${lvs_msg}\n\n")
    }

    $k8s_clusters = k8s::fetch_clusters()

    prometheus::instances().each |$instance, $config| {
        if $facts['networking']['fqdn'] in $config['hosts'] {
            # k8s-related instances are handled separately
            if $config['k8s_cluster_name'] != undef {
                if $config['k8s_cluster_name'] in $k8s_clusters {
                    profile::prometheus::k8s { $instance: }
                }
            } else {
                include "profile::prometheus::${instance}"
            }
        }
    }

    $instances_cleanup.each |$instance, $config| {
        if $facts['networking']['fqdn'] in $config['hosts'] {
            if ! ($facts['volume_groups'] and $facts['volume_groups']['vg0']) {
                fail('prometheus::instances_cleanup requires lvm vg0')
            }
            # Disable and stop services first
            ["prometheus@${instance}", "thanos-sidecar@${instance}"].each |$unit| {
                # cheeky and it works: will fail catalog compilation if the same instance + host is defined in both
                # prometheus::instances and prometheus::instances_cleanup, which is not allowed
                systemd::unit { $unit:
                    ensure  => absent,
                    content => '',
                }

                exec { "disable_${unit}":
                    path    => ['/usr/bin', '/bin'],
                    command => "systemctl disable ${unit}",
                    onlyif  => "systemctl is-enabled ${unit}",
                }
            }

            # Make sure we can umount the filesystem and remove from fstab. The vg0 LV is left alone.
            $mountpoint = "/srv/prometheus/${instance}"
            $fstab_entry = "^/dev/vg0/prometheus-${instance}[[:space:]]+${mountpoint}[[:space:]]+ext4.+"

            exec { "umount_${instance}":
                path    => ['/usr/bin', '/bin'],
                command => "umount ${mountpoint}",
                onlyif  => "mountpoint -q ${mountpoint}",
            }

            file_line { "fstab_remove_${instance}":
                ensure            => absent,
                path              => '/etc/fstab',
                match             => $fstab_entry,
                match_for_absence => true,
                require           => Exec["umount_${instance}"],
            }
        }
    }
}
