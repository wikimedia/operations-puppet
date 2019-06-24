# == Define jmxtrans::metrics
#
# Writes the config file causing this machine to monitor a set of metrics on a
# host.  That file is named /etc/jmxtrans/$title.json.
#
# Suggestion: use these as external resources to force one or more jmxtrans
# installs to monitor this machine.  See jmxtrans::metrics::jvm for an exmple.
#
# == Parameters
# $jmx                  - host:port of JMX to query.
# $objects              - array of hashes of the following form.  See READEME.md for more info.
#   [
#       {
#           "name"        => "JMX object name",
#           "resultAlias" => "pretty alias for JMX name",
#           "typeNames"   => ["name"], # this is optional
#           "attrs"       => {
#               "attribute name" => {
#                   "units" => "unit name",
#                   "slope" => "slope type"
#               }
#           }
#       }
#   ]
#
# $jmx_alias            - Server alias name.              Optional.
# $jmx_username         - JMX username (if there is one)  Optional.
# $jmx_password         - JMX password (if there is one)  Optional.
# $ganglia              - host:port of Ganglia gmond.     Optional.
# $ganglia_group_name   - Ganglia metrics group.          Optional.
# $graphite             - host:port of Graphite server    Optional.
# $graphite_root_prefix - rootPrefix for Graphite.        Optional.
# $statsd               - host:port of statsd server      Optional.
# $statsd_root_prefix   - rootPrefix for statsd.          Optional.
# $outfile              - local file path in which to save metric query results.  Optional.
# $json_dir             - path to jmxtrans JSON config directory.  Default: /etc/jmxtrans.
#
define jmxtrans::metrics(
    $jmx,
    $objects,
    $jmx_alias            = undef,
    $jmx_username         = undef,
    $jmx_password         = undef,
    $ganglia              = undef,
    $ganglia_group_name   = undef,
    $graphite             = undef,
    $graphite_root_prefix = undef,
    $statsd               = undef,
    $statsd_root_prefix   = undef,
    $outfile              = undef,
    $json_dir             = '/etc/jmxtrans',
    $ensure               = 'present',
)
{
    include jmxtrans

    file { "${json_dir}/${title}.json":
        ensure  => $ensure,
        content => template('jmxtrans/jmxtrans.json.erb'),
        notify  => Service['jmxtrans'],
        require => Package['jmxtrans'],
    }
}
