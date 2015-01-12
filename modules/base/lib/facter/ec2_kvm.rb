# Fact: ec2_<EC2 INSTANCE DATA>
#
# This is copied from puppetlabs' facter and slightly modified.
# It is therefore:
# Copyright 2005-2012 Puppet Labs Inc
# and licensed under the Apache 2.0 license.
#
# Upstream facter shipped a broken fact in v2.1 and v2.2 that constrained the
# resolution of the ec2 fact to virtual == xen. This was fixed upstream with
# add124f, released with facter 2.3, but until we incorporate this into our
# infrastructure, roll a version of our own to support kvm-based VMs as well.
#
# For simplicity, ship only the ec2_metadata and not the ec2_userpart part.

def ec2_kvm_run
Facter.define_fact(:ec2_metadata) do
  define_resolution(:rest_kvm) do
    confine do
      Facter.value(:virtual).match /^kvm/
    end

    require 'facter/ec2/rest'

    @querier = Facter::EC2::Metadata.new
    confine do
      @querier.reachable?
    end

    setcode do
      @querier.fetch
    end
  end
end
end

# The flattened version of the EC2 facts are deprecated and will be removed in
# a future release of Facter.
if (ec2_metadata = Facter.value(:ec2_metadata))
  ec2_facts = Facter::Util::Values.flatten_structure("ec2", ec2_metadata)
  ec2_facts.each_pair do |factname, factvalue|
    Facter.add(factname, :value => factvalue)
  end
end

ec2_kvm_run if Facter.version.match(/^2\.[12]/)
