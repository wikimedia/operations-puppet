# Class: profile::analytics::refinery::job::refine_sanitize_salt_rotate
#
# Creates and rotates salts for RefineSanitize jobs.
# This class is intended to be included and configured directly from refine_sanitize.pp
#
# Parameters:
#
# [*salt_names*]
#   Array of salt rotate jobs to declare.  These will be stored locally in
#   $profile::analytics::refinery::config_dir/salts and
#   in HDFS in /user/hdfs/salts.
#
# [*ensure_timers*]
#   Default: present
#
# [*use_kerberos_keytab*]
#   Default: true
#
class profile::analytics::refinery::job::refine_sanitize_salt_rotate(
    Array[String] $salt_names     = lookup('profile::analytics::refinery::job::refine_sanitize_salt_rotate'),
    Wmflib::Ensure $ensure_timers = lookup('profile::analytics::refinery::job::refine_sanitize_salt_rotate::ensure_timers', { 'default_value' => 'present' }),
    Boolean $use_kerberos_keytab  = lookup('profile::analytics::refinery::job::refine_sanitize_salt_rotate::use_kerberos_keytab', { 'default_value' => true }),
) {
    require ::profile::analytics::refinery
    require ::profile::hive::client

    $refinery_path = $::profile::analytics::refinery::path
    $refinery_config_dir = $::profile::analytics::refinery::config_dir

    file { '/usr/local/bin/refinery-salt-rotate':
        ensure  => $ensure_timers,
        content => template('profile/analytics/refinery/job/refinery-salt-rotate.erb'),
        mode    => '0550',
        owner   => 'analytics',
        group   => 'analytics',
    }

    # Need refinery/python on PYTHONPATH to run refinery-salt-rotate
    $systemd_env = {
        'PYTHONPATH' => "\${PYTHONPATH}:${refinery_path}/python",
    }

    # Local directory prefix for salts:
    $local_salts_prefix = "${refinery_config_dir}/salts"
    file { $local_salts_prefix:
        ensure => 'directory',
        owner  => 'analytics',
    }

    # HDFS directory prefix for salts.
    $hdfs_salts_prefix = '/user/hdfs/salts'
    bigtop::hadoop::directory { $hdfs_salts_prefix:
        owner => 'analytics',
        group => 'analytics',
    }

    # Declare a systemd timer to create and rotate salts for each of the declared $salts.
    $salt_names.each |String $salt_name| {
        $local_salts_dir = "${local_salts_prefix}/${salt_name}"
        $hdfs_salts_dir = "${hdfs_salts_prefix}/${salt_name}"

        # Local directory for salts:
        file { $local_salts_dir:
            ensure => 'directory',
            owner  => 'analytics',
        }

        # HDFS direcotry for salts.
        bigtop::hadoop::directory { $hdfs_salts_dir:
            owner => 'analytics',
            group => 'analytics',
        }

        kerberos::systemd_timer { "refinery-salt-rotate-${salt_name}":
            ensure      => $ensure_timers,
            description => "Create, rotate and delete cryptographic salts for ${salt_name}",
            command     => "/usr/local/bin/refinery-salt-rotate ${local_salts_dir} ${hdfs_salts_dir}",
            # Timer runs at midnight (salt rotation time):
            interval    => '*-*-* 00:00:00',
            user        => 'analytics',
            environment => $systemd_env,
            require     => [
                File['/usr/local/bin/refinery-salt-rotate'],
                File[$local_salts_dir],
                Bigtop::Hadoop::Directory[$hdfs_salts_dir],
            ]
        }
    }
}