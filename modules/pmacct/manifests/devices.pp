# Class: pmacct
#
# List of devices speaking netflow/ipfix
#
# IP is needed for iptables rules changes
# port is needed for flow and bpg config
# samplerate is to adjust for sampling

class pmacct::devices {
    # Device Listing
    $list = {
        # tpa - as65001
        cr1-sdtpa => {
            port       => '6511',
            ip         => '208.80.152.196',
            samplerate => '200',
        },
        # Currently running old JunOS and will not sample correctly
        #cr2-pmtpa => {
        #    port       => '6512',
        #    ip         => '208.80.152.197',
        #    samplerate => '1000',
        #},

        # eqiad - as65002
        cr1-eqiad => {
            port       => '6521',
            ip         => '208.80.154.196',
            samplerate => '1000',
        },
        cr2-eqiad => {
            port       => '6522',
            ip         => '208.80.154.197',
            samplerate => '1000',
        },

        # ulsfo - as65003
        cr1-ulsfo => {
            port       => '6531',
            ip         => '198.35.26.192',
            samplerate => '1000',
        },
        cr2-ulsfo => {
            port       => '6532',
            ip         => '198.35.26.193',
            samplerate => '1000',
        },

        # ams - as43821
        cr1-esams => {
            port       => '4381',
            ip         => '91.198.174.245',
            samplerate => '1000',
        },
        cr2-knams => {
            port       => '4382',
            ip         => '91.198.174.246',
            samplerate => '1000',
        },
    }
}
