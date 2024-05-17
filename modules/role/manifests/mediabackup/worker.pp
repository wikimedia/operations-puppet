# mediabackup hosts are used to orchestate and generate
# multimedia (swift) backups for wikis, as well as
# perform recoveries in case of incidents.
# Actual backup storage will live in backup* hosts.
class role::mediabackup::worker {
    include profile::base::production
    include profile::firewall

    include profile::mediabackup::worker
}
