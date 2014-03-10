# Definition: bacula::storage::device
#
# This definition creates SD and director stanzas for archive devices attached
# to an SD
#
# Parameters:
#   $device_type
#       The type of the device. Valid values are File, Tape, Fifo
#   $media_type
#       An arbitrary string used to identify this device.
#   $archive_device
#       The path to a directory, tape drive, or fifo
#   $spool_dir
#       If defined it should be a path to a directory which will be used for
#       spooling
#   $max_spool_size
#       If spool dir is defined this should be too to denote the maximum amount
#       of space that should be consumed in $spool_dir
#
# Actions:
#       Creates local to the SD and exported resources for the director for each
#       archive device
#
# Requires:
#       bacula::storage
#       bacula::director
#
# Sample Usage:
#       bacula::storage::device { 'Tape':
#           device_type    => 'Tape',
#           media_type     => 'LTO4',
#           archive_device => '/dev/nst0',
#           spool_dir      => '/tmp/spool',
#           max_spool_size => '32212254720',
#       }
#
define bacula::storage::device($device_type, $media_type,
                                $archive_device, $max_concur_jobs,
                                $spool_dir=undef, $max_spool_size=undef) {

    $director = $::bacula::storage::director
    $directorpassword = $::bacula::storage::directorpassword
    $sd_port = $::bacula::storage::sd_port

    file { "/etc/bacula/sd-devices.d/${name}.conf":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        notify  => Service['bacula-sd'],
        content => template('bacula/bacula-sd.device.conf.erb'),
        require => File['/etc/bacula/sd-devices.d'],
    }

    # We export ourself to the director
    @@file { "/etc/bacula/storages.d/${::hostname}-${name}.conf":
        ensure  => present,
        owner   => 'root',
        group   => 'bacula',
        mode    => '0640',
        content => template('bacula/bacula-storage.erb'),
        notify  => Service['bacula-director'],
        require => File['/etc/bacula/storages.d'],
        tag     => "bacula-storage-${director}",
    }
}
