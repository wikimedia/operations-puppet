# Force usage of the systemd provider by overriding the stupid defaults
# set by puppetlabs. This is the same thing that the debian package does,
# please see https://salsa.debian.org/puppet-team/puppet/commit/428f6e560dea3cab2f0be39d51806c321bbf6e61
Puppet::Type.type(:service).provide(:systemd).class_eval do
  defaultfor :operatingsystem => :debian
end
