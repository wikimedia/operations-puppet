# Class: nrpe
#
# This installes nrpe packages, ensures service in running and collects all
# configuration
#
# Parameters:
#
# Actions:
#   Install nrpe packages
#   Manage nrpe service status
#   Collect all needed exported resources
#
# Requires:
#   Class[nrpe::packages]
#   Class[nrpe::service]
#   Define[monitor_service]
#
# Sample Usage:
#   include nrpe

class nrpe {
    include nrpe::packages
    include nrpe::service

    #Collect virtual NRPE nagios service checks
    Monitor_service <| tag == 'nrpe' |>
}
