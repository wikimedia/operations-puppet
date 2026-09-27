# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:physical_volume).provider(:lvm)

describe provider_class do
  before(:each) do
    @resource = stub('resource')
    @provider = provider_class.new(@resource)
  end

  pvs_output = <<-OUTPUT
  PV         VG     Fmt  Attr PSize  PFree
  /dev/sda2  centos lvm2 a--  19.51g    0
  /dev/sda3  centos lvm2 a--  10.11g    0
  OUTPUT

  before :each do
    @provider.class.stubs(:pvs).returns(pvs_output)
  end

  describe 'self.instances' do
    it 'returns an array of physical volumes' do
      physical_volumes = @provider.class.instances.map(&:name)

      expect(physical_volumes).to include('/dev/sda2', '/dev/sda3')
    end
  end

  describe 'when creating' do
    it "executes the 'create_physical_volume'" do
      @resource.expects(:[]).with(:name).returns('/dev/hdx')
      @provider.expects(:create_physical_volume).with('/dev/hdx')
      @provider.create
    end
  end

  describe 'when creating with force' do
    it "executes the 'pvcreate' with force option" do
      @resource.expects(:[]).with(:name).returns('/dev/hdx')
      @resource.expects(:[]).with(:force).returns(:true)
      @provider.expects(:pvcreate).with('--force', '/dev/hdx')
      @provider.create
    end
  end

  describe 'when destroying' do
    it "executes 'pvdestroy'" do
      @resource.expects(:[]).with(:name).returns('/dev/hdx')
      @provider.expects(:pvremove).with('/dev/hdx')
      @provider.destroy
    end
  end

  describe 'when checking existence' do
    it "executes 'pvs'" do
      @resource.expects(:[]).with(:unless_vg).returns
      @resource.expects(:[]).with(:name).returns('/dev/sdb')
      @provider.expects(:pvs).returns(true)
      @provider.should be_exists
    end

    it "does not execute 'pvs' if unless_vg VG exists" do
      @resource.expects(:[]).with(:unless_vg).returns('vg01')
      @resource.expects(:[]).with(:unless_vg).returns('vg01')
      @provider.expects(:vgs).returns(true)
      @provider.should be_exists
    end
  end
end
