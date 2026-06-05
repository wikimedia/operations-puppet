# SPDX-License-Identifier: Apache-2.0
class openstack::apply_security_groups (
    Wmflib::Ensure $ensure,
    Hash[String[1], String[1]] $project_and_security_group,
) {
    file { '/usr/local/sbin/add-security-group-to-project':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/openstack/nova/add-security-group-to-project.py',
    }

    $project_and_security_group.each |String $project_id, String $security_group_name| {
        systemd::timer::job { "security_group_${security_group_name}_to_project_${project_id}":
            ensure              => $ensure,
            description         => "Apply security group ${security_group_name} to project ${project_id}",
            command             => "/usr/local/sbin/add-security-group-to-project --os-cloud novadmin  --security-group-name ${security_group_name} --project-id ${project_id}",
            interval            => {
                'start'    => 'OnCalendar',
                'interval' => '*-*-* *:00/30:00', # Every 30 minutes
            },
            max_runtime_seconds => 890,  # kill if running after 14m50s
            logging_enabled     => true,
            monitoring_enabled  => true,
            user                => 'root',
            require             => [
                File['/usr/local/sbin/add-security-group-to-project'],
            ],
        }
    }
}
