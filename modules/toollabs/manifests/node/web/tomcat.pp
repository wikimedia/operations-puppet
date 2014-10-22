# Class: toollabs::node::web::lighttpd
#
# This configures the compute node as a tomcat web server
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::node::web::tomcat inherits toollabs::node::web {

    package { [ 'tomcat7-user', 'xmlstarlet' ]:
        ensure => latest,
    }

    file { "/usr/local/bin/tool-tomcat":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => "puppet:///modules/toollabs/tool-tomcat",
    }

    file { "/usr/local/bin/tomcat-starter":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => "puppet:///modules/toollabs/tomcat-starter",
        require => Package['xmlstarlet'],
    }

}
