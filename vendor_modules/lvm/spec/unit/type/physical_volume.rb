require 'spec_helper'
describe Puppet::Type.type(:physical_volume) do
  it 'raises an ArgumentError when the name is not fully qualified' do
    expect {
      resource = Puppet::Type.type(:physical_volume).new(
				{
        :name         => 'nope',
        :ensure       => :present,
				}
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter name failed on Physical_volume[nope]: Physical Volume names must be fully qualified')
  end

  it 'does not raise an ArgumentError when the name is fully qualified' do
    expect {
      resource = Puppet::Type.type(:physical_volume).new(
				{
        :name         => '/dev/lol',
        :ensure       => :present,
				}
      )
    }.to_not raise_error
  end

  it 'raises an ArgumentError when the volume group name is invalid' do
    expect {
      resource = Puppet::Type.type(:physical_volume).new(
				{
        :name         => '/dev/myvg',
        :unless_vg    => '!not@valid/group$name',
        :ensure       => :present,
				}
      )
    }.to raise_error(Puppet::ResourceError,
                     'Parameter unless_vg failed on Physical_volume[/dev/myvg]: !not@valid/group$name is not a valid volume group name')
  end

  it 'does not raise an ArgumentError when the volume group name is valid' do
    expect {
      resource = Puppet::Type.type(:physical_volume).new(
				{
        :name         => '/dev/myvg',
        :unless_vg    => 'VALIDNAME123',
        :ensure       => :present,
				}
      )
    }.to_not raise_error
  end
end
