require 'spec_helper'

# Generic LVM support
describe 'lvm_support fact' do
  before :each do
    Facter.clear
  end

  context 'when not on Linux' do
    it 'should be set to not' do
      Facter.fact(:kernel).expects(:value).at_least(1).returns('SunOs')
      Facter.value(:lvm_support).should be_nil
    end
  end

  context 'when on Linux' do
    before :each do
      Facter.fact(:kernel).expects(:value).at_least(1).returns('Linux')
    end

    context 'when vgs is absent' do
      it 'should be set to no' do
        Facter::Util::Resolution.stubs('exec') # All other calls
        Facter::Util::Resolution.expects('which').with('vgs').at_least(1).returns(nil)
        Facter.value(:lvm_support).should be_nil
      end
    end

    context 'when vgs is present' do
      it 'should be set to yes' do
        Facter::Util::Resolution.stubs('exec') # All other calls
        Facter::Util::Resolution.expects('which').with('vgs').returns('/sbin/vgs')
        Facter.value(:lvm_support).should be_truthy
      end
    end
  end
end

# VGs
describe 'lvm_vgs facts' do
  before :each do
    Facter.clear
  end

  context 'when there is no lvm support' do
    it 'should not exist' do
      Facter.fact(:lvm_support).expects(:value).at_least(1).returns(nil)
      Facter.value(:lvm_vgs).should be_nil
    end
  end

  context 'when there is lvm support' do
    context 'when there are no vgs' do
      it 'should be set to 0' do
        Facter::Util::Resolution.stubs('exec') # All other calls
        Facter::Util::Resolution.expects('exec').at_least(1).with('vgs -o name --noheadings 2>/dev/null').returns(nil)
        Facter.fact(:lvm_support).expects(:value).at_least(1).returns(true)
        Facter.value(:lvm_vgs).should == 0
      end
    end

    context 'when there are vgs' do
      it 'should list vgs' do
        Facter::Util::Resolution.stubs('exec') # All other calls
        Facter::Util::Resolution.expects('exec').at_least(1).with('vgs -o name --noheadings 2>/dev/null').returns("vg0\nvg1")
        Facter::Util::Resolution.expects('exec').at_least(1).with('vgs -o pv_name vg0 2>/dev/null').returns("  PV\n  /dev/pv3\n  /dev/pv2")
        Facter::Util::Resolution.expects('exec').at_least(1).with('vgs -o pv_name vg1 2>/dev/null').returns("  PV\n  /dev/pv0")
        Facter.fact(:lvm_support).expects(:value).at_least(1).returns(true)
        Facter.value(:lvm_vgs).should == 2
        Facter.value(:lvm_vg_0).should == 'vg0'
        Facter.value(:lvm_vg_1).should == 'vg1'
        Facter.value(:lvm_vg_vg0_pvs).should == '/dev/pv2,/dev/pv3'
        Facter.value(:lvm_vg_vg1_pvs).should == '/dev/pv0'
      end
    end
  end
end

# PVs
describe 'lvm_pvs facts' do
  before :each do
    Facter.clear
  end

  context 'when there is no lvm support' do
    it 'should not exist' do
      Facter.fact(:lvm_support).expects(:value).at_least(1).returns(nil)
      Facter.value(:lvm_pvs).should be_nil
    end
  end

  context 'when there is lvm support' do
    context 'when there are no pvs' do
      it 'should be set to 0' do
        Facter::Util::Resolution.stubs('exec') # All other calls
        Facter::Util::Resolution.expects('exec').at_least(1).with('pvs -o name --noheadings 2>/dev/null').returns(nil)
        Facter.fact(:lvm_support).expects(:value).at_least(1).returns(true)
        Facter.value(:lvm_pvs).should == 0
      end
    end

    context 'when there are pvs' do
      it 'should list pvs' do
        Facter::Util::Resolution.stubs('exec') # All other calls
        Facter::Util::Resolution.expects('exec').at_least(1).with('pvs -o name --noheadings 2>/dev/null').returns("pv0\npv1")
        Facter.fact(:lvm_support).expects(:value).at_least(1).returns(true)
        Facter.value(:lvm_pvs).should == 2
        Facter.value(:lvm_pv_0).should == 'pv0'
        Facter.value(:lvm_pv_1).should == 'pv1'
      end
    end
  end
end
