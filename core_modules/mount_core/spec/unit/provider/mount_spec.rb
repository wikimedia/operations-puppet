require 'spec_helper'

require 'puppet/provider/mount'

describe Puppet::Provider::Mount do
  let(:mounter) do
    mounter = Object.new
    mounter.extend(described_class)
    mounter
  end
  let(:name) { '/' }
  let(:resource) { instance_double(Puppet::Resource) }

  before :each do
    allow(resource).to receive(:[]).with(:name).and_return(name)
    allow(mounter).to receive(:resource).and_return(resource)
  end

  describe described_class, ' when mounting' do
    before :each do
      allow(mounter).to receive(:get).with(:ensure).and_return(:mounted)
    end

    it "uses the 'mountcmd' method to mount" do
      allow(mounter).to receive(:options).and_return(nil)
      expect(mounter).to receive(:mountcmd)

      mounter.mount
    end

    it "adds the options following '-o' on MacOS if they exist and are not set to :absent" do
      expect(Facter).to receive(:value).with(:kernel).and_return 'Darwin'
      allow(mounter).to receive(:options).and_return('ro')
      expect(mounter).to receive(:mountcmd).with '-o', 'ro', '/'

      mounter.mount
    end

    it 'does not explicitly pass mount options on systems other than MacOS' do
      expect(Facter).to receive(:value).with(:kernel).and_return 'HP-UX'
      allow(mounter).to receive(:options).and_return('ro')
      expect(mounter).to receive(:mountcmd).with '/'

      mounter.mount
    end

    it 'specifies the filesystem name to the mount command' do
      allow(mounter).to receive(:options).and_return(nil)
      expect(mounter).to receive(:mountcmd) { |*ary| ary[-1] == name }

      mounter.mount
    end

    it 'updates the :ensure state to :mounted if it was :unmounted before' do
      expect(mounter).to receive(:mountcmd)
      allow(mounter).to receive(:options).and_return(nil)
      expect(mounter).to receive(:get).with(:ensure).and_return(:unmounted)
      expect(mounter).to receive(:set).with(ensure: :mounted)
      mounter.mount
    end

    it 'updates the :ensure state to :ghost if it was :absent before' do
      expect(mounter).to receive(:mountcmd)
      allow(mounter).to receive(:options).and_return(nil)
      expect(mounter).to receive(:get).with(:ensure).and_return(:absent)
      expect(mounter).to receive(:set).with(ensure: :ghost)
      mounter.mount
    end
  end

  describe described_class, ' when remounting' do
    context 'if the resource supports remounting' do
      context 'given explicit options on AIX' do
        it "combines the options with 'remount'" do
          allow(mounter).to receive(:info)
          allow(mounter).to receive(:options).and_return('ro')
          allow(resource).to receive(:[]).with(:remounts).and_return(:true)
          expect(Facter).to receive(:value).with(:operatingsystem).and_return 'AIX'
          expect(mounter).to receive(:mountcmd).with('-o', 'ro,remount', name)
          mounter.remount
        end
      end

      it "uses '-o remount'" do
        allow(mounter).to receive(:info)
        allow(resource).to receive(:[]).with(:remounts).and_return(:true)
        expect(mounter).to receive(:mountcmd).with('-o', 'remount', name)
        mounter.remount
      end
    end

    it "mounts with '-o update' on OpenBSD" do
      allow(mounter).to receive(:info)
      allow(mounter).to receive(:options)
      allow(resource).to receive(:[]).with(:remounts).and_return(false)
      expect(Facter).to receive(:value).with(:operatingsystem).and_return 'OpenBSD'
      expect(mounter).to receive(:mountcmd).with('-o', 'update', name)
      mounter.remount
    end

    it 'unmounts and mount if the resource does not specify it supports remounting' do
      allow(mounter).to receive(:info)
      allow(mounter).to receive(:options)
      allow(resource).to receive(:[]).with(:remounts).and_return(false)
      expect(Facter).to receive(:value).with(:operatingsystem).and_return 'AIX'
      expect(mounter).to receive(:mount)
      expect(mounter).to receive(:unmount)
      mounter.remount
    end

    it 'logs that it is remounting' do
      allow(resource).to receive(:[]).with(:remounts).and_return(:true)
      allow(mounter).to receive(:mountcmd)
      expect(mounter).to receive(:info).with('Remounting')
      mounter.remount
    end
  end

  describe described_class, ' when unmounting' do
    before :each do
      allow(mounter).to receive(:get).with(:ensure).and_return(:unmounted)
    end

    it 'calls the :umount command with the resource name' do
      expect(mounter).to receive(:umount).with(name)
      mounter.unmount
    end

    it 'updates the :ensure state to :absent if it was :ghost before' do
      expect(mounter).to receive(:umount).with(name).and_return true
      expect(mounter).to receive(:get).with(:ensure).and_return(:ghost)
      expect(mounter).to receive(:set).with(ensure: :absent)
      mounter.unmount
    end

    it 'updates the :ensure state to :unmounted if it was :mounted before' do
      expect(mounter).to receive(:umount).with(name).and_return true
      expect(mounter).to receive(:get).with(:ensure).and_return(:mounted)
      expect(mounter).to receive(:set).with(ensure: :unmounted)
      mounter.unmount
    end
  end

  describe described_class, ' when determining if it is mounted' do
    it 'queries the property_hash' do
      expect(mounter).to receive(:get).with(:ensure).and_return(:mounted)
      mounter.mounted?
    end

    it 'returns true if prefetched value is :mounted' do
      allow(mounter).to receive(:get).with(:ensure).and_return(:mounted)
      mounter.mounted? == true
    end

    it 'returns true if prefetched value is :ghost' do
      allow(mounter).to receive(:get).with(:ensure).and_return(:ghost)
      mounter.mounted? == true
    end

    it 'returns false if prefetched value is :absent' do
      allow(mounter).to receive(:get).with(:ensure).and_return(:absent)
      mounter.mounted? == false
    end

    it 'returns false if prefetched value is :unmounted' do
      allow(mounter).to receive(:get).with(:ensure).and_return(:unmounted)
      mounter.mounted? == false
    end
  end
end
