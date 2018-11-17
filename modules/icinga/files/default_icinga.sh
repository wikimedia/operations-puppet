# /etc/default/icinga

# location of the icinga configuration file
ICINGACFG="/etc/icinga/icinga.cfg"

# location of the CGI configuration file
CGICFG="/etc/icinga/cgi.cfg"

# nicelevel to run icinga daemon with
NICENESS=0

# if you use pam_tmpdir, you need to explicitly set TMPDIR:
#TMPDIR=/tmp

# Purge Nagios Resources
# as a startup measure, filter puppet-managed cfg files for only those entries that are in puppet_hosts
/usr/local/sbin/purge-nagios-resources.py /etc/icinga/objects/puppet_hosts.cfg /etc/nagios/puppet_hostgroups.cfg /etc/nagios/puppet_servicegroups.cfg /etc/icinga/objects/puppet_services.cfg
