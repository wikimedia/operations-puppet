# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:volume_group).provider(:lvm)

describe provider_class do
  before(:each) do
    @resource = stub('resource')
    @provider = provider_class.new(@resource)
  end

  vgs_output = <<-OUTPUT
  VG       #PV #LV #SN Attr   VSize  VFree
  VolGroup   1   2   0 wz--n- 19.51g    0
  OUTPUT

  describe 'self.instances' do
    before :each do
      @provider.class.stubs(:vgs).returns(vgs_output)
    end

    it 'returns an array of volume groups' do
      volume_groups = @provider.class.instances.map(&:name)

      expect(volume_groups).to include('VolGroup')
    end
  end

  describe 'when creating' do
    context 'when an extent size is not provided' do
      it "executes 'vgcreate'" do
        @resource.expects(:[]).with(:name).returns('myvg')
        @resource.expects(:[]).with(:extent_size).returns(nil)
        @resource.expects(:should).with(:physical_volumes).returns(['/dev/hda'])
        @provider.expects(:vgcreate).with('myvg', '/dev/hda')
        @provider.create
      end
    end

    context 'when an extent size is provided' do
      it "executes 'vgcreate' with the desired extent size" do
        @resource.expects(:[]).with(:name).returns('myvg')
        @resource.expects(:[]).twice.with(:extent_size).returns('16M')
        @resource.expects(:should).with(:physical_volumes).returns(['/dev/hda'])
        @provider.expects(:vgcreate).with('myvg', '/dev/hda', '-s', '16M')
        @provider.create
      end
    end
  end

  describe 'when destroying' do
    it "executes 'vgremove'" do
      @resource.expects(:[]).with(:name).returns('myvg')
      @provider.expects(:vgremove).with('myvg')
      @provider.destroy
    end
  end
end
