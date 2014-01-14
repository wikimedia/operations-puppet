# Definition: bacula::client::job
#
# This definition exports an job definition to the director for backing up a
# fileset
#
# Parameters:
#   $device_type
#       The type of the device. Valid values are File, Tape, Fifo
#
# Actions:
#       Will create a job definition using the given defaults for the director
#       to collect and then reload itself
#
# Requires:
#       bacula::director
#
# Sample Usage:
#       bacula::client::job { 'rootfs-ourdefaults':
#           fileset     => 'root',
#           jobdefaults => 'ourdefaults',
#       }

define bacula::client::job($fileset, $jobdefaults) {

    $director = $::bacula::client::director

    # We export to the director
    @@file { "/etc/bacula/jobs.d/${::fqdn}-${name}.conf":
        ensure  => present,
        owner   => 'root',
        group   => 'bacula',
        mode    => '0440',
        content => template('bacula/bacula-client-job.erb'),
        notify  => Service['bacula-director'],
        require => File['/etc/bacula/jobs.d'],
        tag     => "bacula-client-${director}",
    }
}
