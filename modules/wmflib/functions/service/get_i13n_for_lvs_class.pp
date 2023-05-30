# SPDX-License-Identifier: Apache-2.0
# For a given traffic class and site, return the hostname that should be used
# for pybal instrumentation access.  This is meant to be called by consuming
# puppetization that wishes to check the metadata provided by pybal in a
# class-abstracted way (fails over with lvs server failover, rather than being
# tied to a specific lvs hostname).
function wmflib::service::get_i13n_for_lvs_class(String $class, String $site) >> Stdlib::Fqdn {
    if $class == 'low-traffic' {
        return "pybal-low-traffic.svc.${site}.wmnet"
    } else {
        return "pybal-${class}-${site}.wikimedia.org"
    }
}
