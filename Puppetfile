moduledir 'vendor_modules'

mod 'concat',
    # NOTE: Deviates from upstream v7.3.0
    #
    # 1. f507466942dbdb0684a1d04ea3d96d62d0ec70fa.:
    #    This commit is reverted as the Regexp.match? operator is not availabe
    #    on ruby 2.3, this commit may be reverted, once all our stretch
    #    hosts are gone.
    :local => true
    # :git => 'https://github.com/puppetlabs/puppetlabs-concat',
    # :ref => 'v7.3.0'

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

mod 'augeasproviders_core',
    :git => 'https://github.com/voxpupuli/puppet-augeasproviders_core.git',
    :ref => '2.7.0'

# NOTE: Forked from upstream, https://github.com/bodgit/puppet-postfix
#
# Contains three pull requests
#
#  1. Add Debian Bullseye(11) support
#  2. Fix support for /etc/aliases
#  3. Debian: don't install Augeas lens for unix-dgram
mod 'postfix',
    :git => 'https://github.com/lollipopman/puppet-postfix',
    :ref => '6fa18a6'
