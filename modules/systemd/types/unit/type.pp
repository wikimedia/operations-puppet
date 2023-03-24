# Taken from `man systemd.unit` on systemd 215, still valid up to systemd 233
type Systemd::Unit::Type = Enum[
        'service', 'socket', 'device', 'mount', 'automount',
        'swap', 'target', 'path', 'timer', 'snapshot', 'slice', 'scope'
]
