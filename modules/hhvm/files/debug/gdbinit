# /etc/gdb/gdbinit: global gdb configuration
# This file was provisioned by Puppet.
set verbose off
set print pretty on
set prompt (\001\033[32m\002gdb\001\033[0m\002)\040

set substitute-path /home/joe/HHVM/hhvm /usr/local/src/hhvm
set substitute-path /usr/src/hhvm /usr/local/src/hhvm

# Don't pause output
set height 0
set width 0

# Load pretty printers for libstdc++
python import sys; sys.path.insert(0, '/usr/share/gcc-4.8/python')
add-auto-load-safe-path /usr/lib/x86_64-linux-gnu

# Load utilities and pretty printers for HHVM
source /usr/local/src/hhvm/hphp/tools/gdb/hhvm.py
