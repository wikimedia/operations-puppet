# == Define: base::crond
#
# The base::crond define is used to create cron configuration files. A
# configuration file is stored in /etc/cron.d/ and is compiled from the
# parameters given to the define. It allows one to set the command, multiple
# execution times, the user to execute as, the environment variables to set and
# where to redirect stdout and stderr.
#
# === Parameters
#
# [*title*]
#   Required. Defines the name of the cron job to add. It is used as the name of
#   the file under /etc/cron.d/
#
# [*command*]
#   Required. The command to execute.
#
# [*time*]
#   Required. The cron time definition(s) of when to execute the command. If an
#   array is given, it will be interpreted as the list of time definitions, and
#   a line in the cron configuration file will be added for each such cron time.
#   The parameter (or each element of the array) can be either a string, array
#   or hash. Strings are taken as being in the crontab time format and will be
#   put in the file as-are. In the case of a hash, the following fields can
#   exist: 'mm', 'hh', 'day', 'mon', 'dow'. They are read in the presented
#   order. If any of them is missing, '*' is assumed. Finally, arrays are taken
#   to be ordered times for each segment, i.e. the array ought to have 5
#   elements; the missing ones are filled with '*'. For example, to indicate
#   that the command should run at 20:30 every day as well as during reboot, one
#   can use: ['@reboot', { mm => 30, hh => 20 }]. Alternatively, the second
#   element could have been written as '50 20 * * *' or [30, 20]. Note, however,
#   that that implies that if you want to run the command only at 20:30 and use
#   an array, you have to specify [[30, 20]].
#
# [*user*]
#   The user under which the command should run. Default: 'root'
#
# [*environment*]
#   The environment variables to set. It can be a string (containing one or more
#   NAME=VALUE pairs separated by new-line characters) or a hash (having
#   variable names as keys and values as values). Note that $PATH is set by the
#   define to /sbin:/usr/sbin:/bin:/usr/bin:/usr/local/sbin:/usr/local/bin . If
#   you need to override it, set it in this parameter. Default: {}
#
# [*redirect*]
#   Tells cron where to redict the output from standard output and error. It can
#   be given as a string or as an array. In the former case, or if the array has
#   only one element, both steams will be redirected to the same destination. If
#   you want to redirect each stream separately, specify it as a two-element
#   array in the [stdout, stderr] format. For example,
#   ['/var/log/my-cron.out', '/var/log/my-cron.err'] would send standard output
#   to the first and standard error to the second element of the array. The
#   default behaviour is to send everything to /dev/null. Default: ['/dev/null']
#
define base::crond(
    $command,
    $time,
    $ensure      = 'present',
    $user        = 'root',
    $environment = {},
    $redirect    = ['/dev/null'],
) {

    validate_ensure($ensure)

    file { "/etc/cron.d/${title}":
        ensure  => $ensure,
        content => template('base/crond.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444'
    }

}
