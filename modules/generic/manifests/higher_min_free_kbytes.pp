class generic::higher_min_free_kbytes {
# Set a high min_free_kbytes watermark.
# See https://wikitech.wikimedia.org/wiki/Dataset1001#Feb_8_2012
# FIXME: Is this setting appropriate to the nodes on which it is applied? Is
# the value optimal? Investigate.
    sysctl::parameters { 'higher_min_free_kbytes':
        values => { 'vm.min_free_kbytes' => 1024 * 256,},
    }
}
