# == toolforge::bastion_proc_management ==
#
# Directly interact with user processes on bastions, initially to limit long
# running processes.
#
# === Parameters ===
#
# [*days_allowed*]
#  Integer. Age, in days, when a process becomes fair game for limiting interactions.
#
# [*script_victims*]
#  Integer. Number of processes for the wmcs_wheel_of_misfortune,py script to
#  kill on a run.
#
# [*min_uid*]
#  Integer. Minimum UID we regard as a "user" process owner.
#
# [*project*]
#  String. Cloud VPS project this is running on.
#
# === Example ===
#
# A accepting defaults, but setting the project correctly.
#
# class { 'toolforge::bastion_proc_management':
#        project => $::labsproject,
#    }

class toolforge::bastion_proc_management (
    Integer $days_allowed = 3,
    Integer $script_victims = 2,
    Integer $min_uid = 500,
    String  $project = 'tools',
){
    require_package('python3-psutil')
    require_package('python3-ldap3')

    # Script to stop long-running services, sometimes
    file { '/usr/local/sbin/wmcs-wheel-of-misfortune':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/toolforge/wmcs_wheel_of_misfortune.py'
    }

    # Expose args in a way that is CLI friendly as well as not a 1000 char line.
    $main_cmd = '/usr/local/sbin/wmcs-wheel-of-misfortune'
    $proj = " --project ${project}"
    $age = " --age ${days_allowed}"
    $uids = " --min-uid ${min_uid}"
    $vics = " --victims ${script_victims}"
    $timer_cmd = "${main_cmd}${proj}${age}${uids}${vics}"

    systemd::timer::job { 'wmcs-wheel-of-misfortune-runner':
        ensure                    => 'present',
        # Don't log to file, use journald
        logging_enabled           => false,
        user                      => 'root',
        description               => 'Select long-running processes for destruction',
        command                   => $timer_cmd,
        interval                  => {
        'start'    => 'OnCalendar',
        'interval' => '*-*-* *:30:00', # hourly at half-past
        },
        monitoring_enabled        => true,
        monitoring_contact_groups => 'wmcs-team-email',
        require                   => File[
            '/usr/local/sbin/wmcs-wheel-of-misfortune',
        ],
    }
}
