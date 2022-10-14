# SPDX-License-Identifier: Apache-2.0
class profile::dumps::generation::worker::monitor {
    class { '::snapshot::dumps::monitor':
        xmldumpsuser  => 'dumpsgen',
        xmldumpsgroup => 'dumpsgen',
    }
    $xmldumpsmount = '/mnt/dumpsdata'
    class { '::snapshot::dumps::timechecker':
        xmldumpsuser => 'dumpsgen',
        dumpsbasedir => "${xmldumpsmount}/xmldatadumps/public",
    }
}
