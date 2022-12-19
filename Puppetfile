moduledir 'vendor_modules'

mod 'concat',
    :git => 'https://github.com/puppetlabs/puppetlabs-concat',
    :ref => 'v7.3.0'

mod 'lvm',
    # NOTE: Deviates from upstream v1.4.0
    #
    # 1. 6d5f32c127099005dcab88dda381b4184e1ff1cd:
    #    Force volume group removal
    #
    # 2. 97a762cb7b4a78eaa173176bc0f77852dc5f38b0:
    #    Increase timeout for facts, adds --noheadings
    #
    :local => true
    # :git => 'https://github.com/puppetlabs/puppetlabs-lvm',
    # :ref => 'v1.4.0'

mod 'puppetdbquery',
    :git => 'https://github.com/dalen/puppet-puppetdbquery.git',
    :ref => '3.0.1'

mod 'stdlib',
    :git => 'https://github.com/puppetlabs/puppetlabs-stdlib',
    :ref => 'v8.1.0'
