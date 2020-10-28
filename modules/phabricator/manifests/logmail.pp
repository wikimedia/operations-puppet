# == Class: phabricator::logmail
#
# once used for admin audit log and community metrics
# on Bugzilla, now for similar metrics on Phabricator
# but can be flexible about the script it uses
#
# === Required Parameters
#
# [*rcpt_address*]
#   mail to: address (or array of addresses)
#
# [*sndr_address*]
#   mail from: address
#
# [*mysql_slave*]
#   mysql (slave) server
#
# [*mysql_slave_port*]
#   port of the mysql (slave) server
#
# [*mysql_db_name*]
#   name of the mysql database accessed by the script
#
# === Optional Parameters
#
# [*basedir*]
#    path to the phabricator tools directory
#
# [*hour*]
#    hour the script is executed
#
# [*minute*]
#    minute the script is executed
#
# [*monthday*]
#    day of the month script is executed
#
# [*weekday*]
#    day of the week script is executed
#
# [*ensure*]
#    Whether to enable the cron or not, default present

define phabricator::logmail (
    String $sndr_address,
    Variant[String, Array] $rcpt_address,
    Stdlib::Fqdn $mysql_slave,
    Stdlib::Port $mysql_slave_port,
    String $mysql_db_name,
    Stdlib::Unixpath $basedir  = '/usr/local/bin',
    Optional[Integer] $hour = 0,
    Optional[Integer] $minute = 0,
    Optional[Integer] $monthday = undef,
    Optional[Integer] $weekday = undef,
    Wmflib::Ensure $ensure = 'present',
) {

    ensure_packages(['mariadb-client', 'bsd-mailx'])

    file { "/etc/phab_${title}.conf":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0550',
        content => template("phabricator/${title}.conf.erb"),
    }

    file { "${basedir}/${title}.sh":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0550',
        content => file("phabricator/${title}.sh"),
    }

    cron { "phabstatscron_${title}":
        ensure   => $ensure,
        command  => "${basedir}/${title}.sh",
        user     => 'root',
        hour     => $hour,
        minute   => $minute,
        weekday  => $weekday,
        monthday => $monthday,
    }
}
