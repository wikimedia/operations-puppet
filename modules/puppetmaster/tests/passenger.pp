# TODO: At some point this should not be needed
import '../../../manifests/nagios.pp'
import '../../../manifests/backups.pp'
import '../../../manifests/role/backup.pp'

include puppetmaster::passenger
