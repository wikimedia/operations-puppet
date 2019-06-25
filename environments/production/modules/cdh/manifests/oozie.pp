# == Class cdh::oozie
# Installs the oozie-client package
# And sets OOZIE_URL in /etc/profile.d/oozie.sh.
#
class cdh::oozie(
    $oozie_host = 'localhost'
)
{
    # oozie server url
    $url = "http://${oozie_host}:11000/oozie"

    package { 'oozie-client':
        ensure => 'installed',
    }

    # create a file in /etc/profile.d to export OOZIE_URL.
    file { '/etc/profile.d/oozie.sh':
        content => "# NOTE:  This file is managed by Puppet.

export OOZIE_URL='${url}'
",
        mode    => '0444',
    }
}
