# modules/pmacct/configuration.pp
# Defines specific agent configuration for pmacct

class role::pmacct {
    system::role { 'role::pmacct':
        description => '(network monitoring) flow accounting '}

    # Behave differently in labs from production
    case $::realm {
        'labs': {
            # Database connectivity
            $pmacct_database = {
                host => '127.0.01',
                name => 'pmacct',
                user => 'pmacct',
                pass => 'pmacct',
            }

            # Agent definitions
            $pmacct_agents = {
                # tpa - as65001
                testing  => {
                    port       => '12333',
                    ip         => '123.123.123.123',
                    samplerate => '123',
                    },
                } # end of agents
        }
        'production': {
            # Database connectivity (placeholder)
            $pmacct_database = {
                host => '127.0.01',
                name => 'pmacct',
                user => 'pmacct',
                pass => 'pmacct',
            }

            # Agent definitions
            $pmacct_agents = {
                # tpa - as65001
                # Currently running old JunOS and will not sample correctly
                #cr2-pmtpa => {
                    #port       => '6512',
                    #ip         => '208.80.152.197',
                    #samplerate => '1000',
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
                }
                } # end of agents

        }
        default: {
            fail('unknown realm, should be labs or production')
        }
    }

    # the 'pmacct' class from modules/pmacct/init.pp does the setup
    class {'::pmacct':
        pmacct_database => $pmacct_database,
        pmacct_agents   => $pmacct_agents,
    }
}
