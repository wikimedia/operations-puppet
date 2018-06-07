# == Define kafkatee::output
# Configures a kafkatee output.
#
# == Parameters
# $instance_name    - Name of kafkatee::instance.
#
# $destination      - Where this output will be sent.  If $type is
#                     'file', then this should be a file path.  Otherwise
#                     it should be a process that receives input from stdin.
# $type             - Type of kafkatee output.  Either 'file' or 'pipe'.
#                     Default: file
# $sample           - The sample rate denominator (1/$sample).
#                     e.g. 1 means 100%, 1/10 means 10%, etc.
#
define kafkatee::output(
    $instance_name,
    $destination,
    $type           = 'file',
    $sample         = 1,
    $ensure         = 'present',
)
{
    file { "/etc/kafkatee/${instance_name}.outputs/output.${title}.conf":
        ensure  => $ensure,
        content => template('kafkatee/output.conf.erb'),
        notify  => Service["kafkatee-${instance_name}"],
    }
}
