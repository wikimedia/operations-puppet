#   Class: base::platform
#
#   This class implements hardware platform specific configuration
class base::platform {
    case $::productname {
        'PowerEdge C2100': {
            $startup_drives = [ '/dev/sda', '/dev/sdb' ]
        }
        'PowerEdge R300': {
            $startup_drives = [ '/dev/sda', '/dev/sdb']
            include base::platform::dell-r300
        }
        'R250-2480805': {
            $startup_drives = [ '/dev/sda', '/dev/sdb' ]
            include base::platform::cisco-C250-M1
        }
        default: {
            # set something so the logic doesn't puke
            $startup_drives = [ '/dev/sda', '/dev/sdb' ]
        }
    }
}