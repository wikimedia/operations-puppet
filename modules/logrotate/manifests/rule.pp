# SPDX-License-Identifier: Apache-2.0
# @summary Provides a common template that can be used by different applications to
#   configure log rotation. See logrotate man page for detailed documentation.
#
#   Most parameters of this class map directly to the corresponding logrotate
#   options.
#
# @param file_glob The file glob to act on
# @param ensure the ensureable parameter
# @param frequency frequency of log rotation, must be in daily, weekly, monthly or yearly.
# @param not_if_empty if the file is empty to nothing
# @param date_yesterday Use yesterday's instead of today's date to create the date extension
# @param copy_truncate Truncate the original log file to zero size in place after creating a copy
# @param max_age remove rotated logs older than <count> days
# @param rotate Log files are rotated count times before being removed or mailed to the address specified
#   in a mail directive
# @param date_ext Archive old versions of log files adding a date extension
# @param compress Old versions of log files are compressed
# @param missing_ok If the log file is missing, go on to the next one without issuing an error message
# @param size Log files are rotated only if they grow bigger than size bytes
# @param no_create New log files are not created
# @param post_rotate The script is executed after the log file is rotated
# @param su Rotate log files set under this user and group
# @param create Immediately after rotation (before the postrotate script is run) the log file is created
#   (with the same name as the log file just rotated)
# @param old_dir Logs are moved into directory for rotation
#
define logrotate::rule (
    String                         $file_glob,
    Wmflib::Ensure                 $ensure         = present,
    Optional[Logrotate::Frequency] $frequency      = undef,
    Boolean                        $not_if_empty   = false,
    Boolean                        $date_yesterday = false,
    Boolean                        $copy_truncate  = false,
    Optional[Integer[1]]           $max_age        = undef,
    Optional[Integer[1]]           $rotate         = undef,
    Boolean                        $date_ext       = false,
    Boolean                        $compress       = false,
    Boolean                        $missing_ok     = false,
    Optional[Stdlib::Datasize]     $size           = undef,
    Boolean                        $no_create      = false,
    Optional[String[1]]            $post_rotate    = undef,
    Optional[String[1]]            $su             = undef,
    Optional[String[1]]            $create         = undef,
    Optional[Stdlib::Unixpath]     $old_dir        = undef,
) {
    $actual_size = $size.then |$s| {
        ($frequency =~ Undef).bool2str("size ${s}", "maxsize ${s}")
    }

    logrotate::conf { $title:
        ensure  => $ensure,
        content => template('logrotate/logrotate.erb'),
    }
}
