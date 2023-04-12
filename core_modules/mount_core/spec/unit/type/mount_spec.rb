require 'spec_helper'

describe Puppet::Type.type(:mount), unless: Puppet.features.microsoft_windows? do
  before :each do
    allow(Puppet::Type.type(:mount)).to receive(:defaultprovider).and_return providerclass
  end

  let :providerclass do
    described_class.provide(:fake_mount_provider) do
      attr_accessor :property_hash
      def create; end

      def destroy; end

      def exists?
        get(:ensure) != :absent
      end

      def mount; end

      def umount; end

      def mounted?
        [:mounted, :ghost].include?(get(:ensure))
      end
      mk_resource_methods
    end
  end

  let :provider do
    providerclass.new(name: 'yay')
  end

  let :resource do
    described_class.new(name: 'yay', audit: :ensure, provider: provider)
  end

  let :ensureprop do
    resource.property(:ensure)
  end

  it 'has a :refreshable feature that requires the :remount method' do
    expect(described_class.provider_feature(:refreshable).methods).to eq([:remount])
  end

  it 'has no default value for :ensure' do
    mount = described_class.new(name: 'yay')
    expect(mount.should(:ensure)).to be_nil
  end

  it 'has :name as the only keyattribut' do
    expect(described_class.key_attributes).to eq([:name])
  end

  describe 'when validating attributes' do
    [:name, :remounts, :provider].each do |param|
      it "has a #{param} parameter" do
        expect(described_class.attrtype(param)).to eq(:param)
      end
    end

    [:ensure, :device, :blockdevice, :fstype, :options, :pass, :dump, :atboot, :target].each do |param|
      it "has a #{param} property" do
        expect(described_class.attrtype(param)).to eq(:property)
      end
    end
  end

  describe 'when validating values' do
    describe 'for name' do
      it 'allows full qualified paths' do
        expect(described_class.new(name: '/mnt/foo')[:name]).to eq('/mnt/foo')
      end

      it 'removes trailing slashes' do
        expect(described_class.new(name: '/')[:name]).to eq('/')
        expect(described_class.new(name: '//')[:name]).to eq('/')
        expect(described_class.new(name: '/foo/')[:name]).to eq('/foo')
        expect(described_class.new(name: '/foo/bar/')[:name]).to eq('/foo/bar')
        expect(described_class.new(name: '/foo/bar/baz//')[:name]).to eq('/foo/bar/baz')
      end

      describe 'for whitespace' do
        it 'does not allow spaces when kernel is not Linux' do
          allow(Facter).to receive(:value).with(:kernel).and_return 'Darwin'
          expect { described_class.new(name: '/mnt/foo bar') }.to raise_error Puppet::Error, %r{name.*whitespace}
        end

        it 'allows spaces when kernel is Linux' do
          allow(Facter).to receive(:value).with(:kernel).and_return 'Linux'
          expect { described_class.new(name: '/mnt/foo bar') }.not_to raise_error Puppet::Error, %r{name.*whitespace}
        end
      end

      it 'allows pseudo mountpoints (e.g. swap)' do
        expect(described_class.new(name: 'none')[:name]).to eq('none')
      end
    end

    describe 'for ensure' do
      it 'aliases :present to :defined as a value to :ensure' do
        mount = described_class.new(name: 'yay', ensure: :present)
        expect(mount.should(:ensure)).to eq(:defined)
      end

      it 'supports :present as a value to :ensure' do
        expect { described_class.new(name: 'yay', ensure: :present) }.not_to raise_error
      end

      it 'supports :defined as a value to :ensure' do
        expect { described_class.new(name: 'yay', ensure: :defined) }.not_to raise_error
      end

      it 'supports :unmounted as a value to :ensure' do
        expect { described_class.new(name: 'yay', ensure: :unmounted) }.not_to raise_error
      end

      it 'supports :absent as a value to :ensure' do
        expect { described_class.new(name: 'yay', ensure: :absent) }.not_to raise_error
      end

      it 'supports :mounted as a value to :ensure' do
        expect { described_class.new(name: 'yay', ensure: :mounted) }.not_to raise_error
      end

      it 'does not support other values for :ensure' do
        expect { described_class.new(name: 'yay', ensure: :mount) }.to raise_error Puppet::Error, %r{Invalid value}
      end
    end

    describe 'for device' do
      it 'supports normal /dev paths for device' do
        expect { described_class.new(name: '/foo', ensure: :present, device: '/dev/hda1') }.not_to raise_error
        expect { described_class.new(name: '/foo', ensure: :present, device: '/dev/dsk/c0d0s0') }.not_to raise_error
      end

      it 'supports labels for device' do
        expect { described_class.new(name: '/foo', ensure: :present, device: 'LABEL=/boot') }.not_to raise_error
        expect { described_class.new(name: '/foo', ensure: :present, device: 'LABEL=SWAP-hda6') }.not_to raise_error
      end

      it 'supports pseudo devices for device' do
        expect { described_class.new(name: '/foo', ensure: :present, device: 'ctfs') }.not_to raise_error
        expect { described_class.new(name: '/foo', ensure: :present, device: 'swap') }.not_to raise_error
        expect { described_class.new(name: '/foo', ensure: :present, device: 'sysfs') }.not_to raise_error
        expect { described_class.new(name: '/foo', ensure: :present, device: 'proc') }.not_to raise_error
      end

      describe 'for whitespace' do
        it 'does not allow spaces when kernel is not Linux' do
          allow(Facter).to receive(:value).with(:kernel).and_return 'Darwin'
          expect { described_class.new(name: '/foo', ensure: :present, device: '/dev/my dev/foo') }.to raise_error Puppet::Error, %r{device.*whitespace}
          expect { described_class.new(name: '/foo', ensure: :present, device: "/dev/my\tdev/foo") }.to raise_error Puppet::Error, %r{device.*whitespace}
        end

        it 'does allow spaces when kernel is Linux' do
          allow(Facter).to receive(:value).with(:kernel).and_return 'Linux'
          expect { described_class.new(name: '/foo', ensure: :present, device: '/dev/my dev/foo') }.not_to raise_error Puppet::Error, %r{device.*whitespace}
          expect { described_class.new(name: '/foo', ensure: :present, device: "/dev/my\tdev/foo") }.not_to raise_error Puppet::Error, %r{device.*whitespace}
        end
      end

      it 'does not support whitespace in device' do
      end
    end

    describe 'for blockdevice' do
      before :each do
        # blockdevice is only used on Solaris
        [:osfamily, :operatingsystem, :kernel].each do |fact|
          allow(Facter).to receive(:value).with(fact).and_return 'Solaris'
        end
      end

      it 'supports normal /dev/rdsk paths for blockdevice' do
        expect { described_class.new(name: '/foo', ensure: :present, blockdevice: '/dev/rdsk/c0d0s0') }.not_to raise_error
      end

      it 'supports a dash for blockdevice' do
        expect { described_class.new(name: '/foo', ensure: :present, blockdevice: '-') }.not_to raise_error
      end

      it 'does not support whitespace in blockdevice' do
        expect { described_class.new(name: '/foo', ensure: :present, blockdevice: '/dev/my dev/foo') }.to raise_error Puppet::Error, %r{blockdevice.*whitespace}
        expect { described_class.new(name: '/foo', ensure: :present, blockdevice: "/dev/my\tdev/foo") }.to raise_error Puppet::Error, %r{blockdevice.*whitespace}
      end

      it 'defaults to /dev/rdsk/DEVICE if device is /dev/dsk/DEVICE' do
        obj = described_class.new(name: '/foo', device: '/dev/dsk/c0d0s0')
        expect(obj[:blockdevice]).to eq('/dev/rdsk/c0d0s0')
      end

      it 'defaults to - if it is an nfs-share' do
        obj = described_class.new(name: '/foo', device: 'server://share', fstype: 'nfs')
        expect(obj[:blockdevice]).to eq('-')
      end

      it 'has no default otherwise' do
        expect(described_class.new(name: '/foo')[:blockdevice]).to eq(nil)
        expect(described_class.new(name: '/foo', device: '/foo')[:blockdevice]).to eq(nil)
      end

      it 'overwrites any default if blockdevice is explicitly set' do
        expect(described_class.new(name: '/foo', device: '/dev/dsk/c0d0s0', blockdevice: '/foo')[:blockdevice]).to eq('/foo')
        expect(described_class.new(name: '/foo', device: 'server://share', fstype: 'nfs', blockdevice: '/foo')[:blockdevice]).to eq('/foo')
      end
    end

    describe 'for fstype' do
      it 'supports valid fstypes' do
        expect { described_class.new(name: '/foo', ensure: :present, fstype: 'ext3') }.not_to raise_error
        expect { described_class.new(name: '/foo', ensure: :present, fstype: 'proc') }.not_to raise_error
        expect { described_class.new(name: '/foo', ensure: :present, fstype: 'sysfs') }.not_to raise_error
      end

      it 'supports auto as a special fstype' do
        expect { described_class.new(name: '/foo', ensure: :present, fstype: 'auto') }.not_to raise_error
      end

      it 'does not support whitespace in fstype' do
        expect { described_class.new(name: '/foo', ensure: :present, fstype: 'ext 3') }.to raise_error Puppet::Error, %r{fstype.*whitespace}
      end

      it 'does not support an empty string in fstype' do
        expect { described_class.new(name: '/foo', ensure: :present, fstype: '') }.to raise_error Puppet::Error, %r{fstype.*empty string}
      end
    end

    describe 'for options' do
      it 'supports a single option' do
        expect { described_class.new(name: '/foo', ensure: :present, options: 'ro') }.not_to raise_error
      end

      it 'supports multiple options as a comma separated list' do
        expect { described_class.new(name: '/foo', ensure: :present, options: 'ro,rsize=4096') }.not_to raise_error
      end

      it 'does not support whitespace in options' do
        expect { described_class.new(name: '/foo', ensure: :present, options: ['ro', 'foo bar', 'intr']) }.to raise_error Puppet::Error, %r{option.*whitespace}
      end

      it 'does not support an empty string in options' do
        expect { described_class.new(name: '/foo', ensure: :present, options: '') }.to raise_error Puppet::Error, %r{option.*empty string}
      end
    end

    describe 'for pass' do
      it 'supports numeric values' do
        expect { described_class.new(name: '/foo', ensure: :present, pass: '0') }.not_to raise_error
        expect { described_class.new(name: '/foo', ensure: :present, pass: '1') }.not_to raise_error
        expect { described_class.new(name: '/foo', ensure: :present, pass: '2') }.not_to raise_error
      end

      it 'supports - on Solaris' do
        [:osfamily, :operatingsystem, :kernel].each do |fact|
          allow(Facter).to receive(:value).with(fact).and_return 'Solaris'
        end
        expect { described_class.new(name: '/foo', ensure: :present, pass: '-') }.not_to raise_error
      end

      it 'defaults to 0 on non Solaris' do
        [:osfamily, :operatingsystem, :kernel].each do |fact|
          allow(Facter).to receive(:value).with(fact).and_return 'HP-UX'
        end
        expect(described_class.new(name: '/foo', ensure: :present)[:pass]).to eq(0)
      end

      it 'defaults to - on Solaris' do
        [:osfamily, :operatingsystem, :kernel].each do |fact|
          allow(Facter).to receive(:value).with(fact).and_return 'Solaris'
        end
        expect(described_class.new(name: '/foo', ensure: :present)[:pass]).to eq('-')
      end
    end

    describe 'for dump' do
      it 'supports 0 as a value for dump' do
        expect { described_class.new(name: '/foo', ensure: :present, dump: '0') }.not_to raise_error
      end

      it 'supports 1 as a value for dump' do
        expect { described_class.new(name: '/foo', ensure: :present, dump: '1') }.not_to raise_error
      end

      # Unfortunately the operatingsystem is evaluatet at load time so I am unable to double operatingsystem
      it 'supports 2 as a value for dump on FreeBSD', if: Facter.value(:operatingsystem) == 'FreeBSD' do
        expect { described_class.new(name: '/foo', ensure: :present, dump: '2') }.not_to raise_error
      end

      it 'does not support 2 as a value for dump when not on FreeBSD', if: Facter.value(:operatingsystem) != 'FreeBSD' do
        expect { described_class.new(name: '/foo', ensure: :present, dump: '2') }.to raise_error Puppet::Error, %r{Invalid value}
      end

      it 'defaults to 0' do
        expect(described_class.new(name: '/foo', ensure: :present)[:dump]).to eq(0)
      end
    end

    describe 'for atboot' do
      it 'does not allow non-boolean values' do
        expect { described_class.new(name: '/foo', ensure: :present, atboot: 'unknown') }.to raise_error Puppet::Error, %r{expected a boolean value}
      end

      it 'interprets yes as yes' do
        resource = described_class.new(name: '/foo', ensure: :present, atboot: :yes)

        expect(resource[:atboot]).to eq(:yes)
      end

      it 'interprets true as yes' do
        resource = described_class.new(name: '/foo', ensure: :present, atboot: :true)

        expect(resource[:atboot]).to eq(:yes)
      end

      it 'interprets no as no' do
        resource = described_class.new(name: '/foo', ensure: :present, atboot: :no)

        expect(resource[:atboot]).to eq(:no)
      end

      it 'interprets false as no' do
        resource = described_class.new(name: '/foo', ensure: :present, atboot: false)

        expect(resource[:atboot]).to eq(:no)
      end
    end
  end

  describe 'when changing the host' do
    def test_ensure_change(options)
      provider.set(ensure: options[:from])
      expect(provider).to receive(:create).exactly(options[:create] || 0).times
      expect(provider).to receive(:destroy).exactly(options[:destroy] || 0).times
      expect(provider).not_to receive(:mount)
      expect(provider).to receive(:unmount).exactly(options[:unmount] || 0).times
      allow(ensureprop).to receive(:syncothers)
      ensureprop.should = options[:to]
      ensureprop.sync
      expect(!!provider.property_hash[:needs_mount]).to eq(!!options[:mount])
    end

    it 'creates itself when changing from :ghost to :present' do
      test_ensure_change(from: :ghost, to: :present, create: 1)
    end

    it 'creates itself when changing from :absent to :present' do
      test_ensure_change(from: :absent, to: :present, create: 1)
    end

    it 'creates itself and unmount when changing from :ghost to :unmounted' do
      test_ensure_change(from: :ghost, to: :unmounted, create: 1, unmount: 1)
    end

    it 'unmounts resource when changing from :mounted to :unmounted' do
      test_ensure_change(from: :mounted, to: :unmounted, unmount: 1)
    end

    it 'creates itself when changing from :absent to :unmounted' do
      test_ensure_change(from: :absent, to: :unmounted, create: 1)
    end

    it 'unmounts resource when changing from :ghost to :absent' do
      test_ensure_change(from: :ghost, to: :absent, unmount: 1)
    end

    it 'unmounts and destroy itself when changing from :mounted to :absent' do
      test_ensure_change(from: :mounted, to: :absent, destroy: 1, unmount: 1)
    end

    it 'destroys itself when changing from :unmounted to :absent' do
      test_ensure_change(from: :unmounted, to: :absent, destroy: 1)
    end

    it 'creates itself when changing from :ghost to :mounted' do
      test_ensure_change(from: :ghost, to: :mounted, create: 1)
    end

    it 'creates itself and mount when changing from :absent to :mounted' do
      test_ensure_change(from: :absent, to: :mounted, create: 1, mount: 1)
    end

    it 'mounts resource when changing from :unmounted to :mounted' do
      test_ensure_change(from: :unmounted, to: :mounted, mount: 1)
    end

    it 'is in sync if it is :absent and should be :absent' do
      ensureprop.should = :absent
      expect(ensureprop.safe_insync?(:absent)).to eq(true)
    end

    it 'is out of sync if it is :absent and should be :defined' do
      ensureprop.should = :defined
      expect(ensureprop.safe_insync?(:absent)).to eq(false)
    end

    it 'is out of sync if it is :absent and should be :mounted' do
      ensureprop.should = :mounted
      expect(ensureprop.safe_insync?(:absent)).to eq(false)
    end

    it 'is out of sync if it is :absent and should be :unmounted' do
      ensureprop.should = :unmounted
      expect(ensureprop.safe_insync?(:absent)).to eq(false)
    end

    it 'is out of sync if it is :mounted and should be :absent' do
      ensureprop.should = :absent
      expect(ensureprop.safe_insync?(:mounted)).to eq(false)
    end

    it 'is in sync if it is :mounted and should be :defined' do
      ensureprop.should = :defined
      expect(ensureprop.safe_insync?(:mounted)).to eq(true)
    end

    it 'is in sync if it is :mounted and should be :mounted' do
      ensureprop.should = :mounted
      expect(ensureprop.safe_insync?(:mounted)).to eq(true)
    end

    it 'is out in sync if it is :mounted and should be :unmounted' do
      ensureprop.should = :unmounted
      expect(ensureprop.safe_insync?(:mounted)).to eq(false)
    end

    it 'is out of sync if it is :unmounted and should be :absent' do
      ensureprop.should = :absent
      expect(ensureprop.safe_insync?(:unmounted)).to eq(false)
    end

    it 'is in sync if it is :unmounted and should be :defined' do
      ensureprop.should = :defined
      expect(ensureprop.safe_insync?(:unmounted)).to eq(true)
    end

    it 'is out of sync if it is :unmounted and should be :mounted' do
      ensureprop.should = :mounted
      expect(ensureprop.safe_insync?(:unmounted)).to eq(false)
    end

    it 'is in sync if it is :unmounted and should be :unmounted' do
      ensureprop.should = :unmounted
      expect(ensureprop.safe_insync?(:unmounted)).to eq(true)
    end

    it 'is out of sync if it is :ghost and should be :absent' do
      ensureprop.should = :absent
      expect(ensureprop.safe_insync?(:ghost)).to eq(false)
    end

    it 'is out of sync if it is :ghost and should be :defined' do
      ensureprop.should = :defined
      expect(ensureprop.safe_insync?(:ghost)).to eq(false)
    end

    it 'is out of sync if it is :ghost and should be :mounted' do
      ensureprop.should = :mounted
      expect(ensureprop.safe_insync?(:ghost)).to eq(false)
    end

    it 'is out of sync if it is :ghost and should be :unmounted' do
      ensureprop.should = :unmounted
      expect(ensureprop.safe_insync?(:ghost)).to eq(false)
    end
  end

  describe 'when responding to refresh' do
    pending '2.6.x specifies slightly different behavior and the desired behavior needs to be clarified and revisited.  See ticket #4904' do
      it 'remounts if it is supposed to be mounted' do
        resource[:ensure] = 'mounted'
        expect(provider).to receive(:remount)

        resource.refresh
      end

      it 'does not remount if it is supposed to be present' do
        resource[:ensure] = 'present'
        expect(provider).not_to receive(:remount)

        resource.refresh
      end

      it 'does not remount if it is supposed to be absent' do
        resource[:ensure] = 'absent'
        expect(provider).not_to receive(:remount)

        resource.refresh
      end

      it 'does not remount if it is supposed to be defined' do
        resource[:ensure] = 'defined'
        expect(provider).not_to receive(:remount)

        resource.refresh
      end

      it 'does not remount if it is supposed to be unmounted' do
        resource[:ensure] = 'unmounted'
        expect(provider).not_to receive(:remount)

        resource.refresh
      end

      it 'does not remount swap filesystems' do
        resource[:ensure] = 'mounted'
        resource[:fstype] = 'swap'
        expect(provider).not_to receive(:remount)

        resource.refresh
      end
    end
  end

  describe 'when modifying an existing mount entry' do
    let :initial_values do
      {
        ensure: :mounted,
        name: '/mnt/foo',
        device: '/foo/bar',
        blockdevice: '/other/bar',
        target: '/what/ever',
        options: 'soft',
        pass: 0,
        dump: 0,
        atboot: :no,
      }
    end

    let :resource do
      described_class.new(initial_values.merge(provider: provider))
    end

    let :provider do
      providerclass.new(initial_values)
    end

    def run_in_catalog(*resources)
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(Puppet::Transaction::Persistence).to receive(:save) if Puppet.version.to_f < 5.0
      # rubocop:enable RSpec/AnyInstance
      allow(Puppet::Util::Storage).to receive(:store)
      catalog = Puppet::Resource::Catalog.new
      catalog.add_resource(*resources)
      catalog.apply
    end

    it 'uses the provider to change the dump value' do
      expect(provider).to receive(:dump=).with(1)

      resource[:dump] = 1

      run_in_catalog(resource)
    end

    it 'umounts before flushing changes to disk' do
      expect(provider).to receive(:unmount).ordered
      expect(provider).to receive(:options=).with('hard').ordered
      expect(resource).to receive(:flush).ordered # Call inside syncothers
      expect(resource).to receive(:flush).ordered # I guess transaction or anything calls flush again

      resource[:ensure] = :unmounted
      resource[:options] = 'hard'

      run_in_catalog(resource)
    end
  end

  describe 'establishing autorequires and autobefores' do
    def create_mount_resource(path)
      described_class.new(
        name: path,
        provider: providerclass.new(path),
      )
    end

    def create_file_resource(path)
      file_class = Puppet::Type.type(:file)
      file_class.new(
        path: path,
        provider: file_class.new(path: path).provider,
      )
    end

    def create_catalog(*resources)
      catalog = Puppet::Resource::Catalog.new
      resources.each do |resource|
        catalog.add_resource resource
      end

      catalog
    end

    let(:root_mount) { create_mount_resource('/') }
    let(:var_mount)  { create_mount_resource('/var') }
    let(:log_mount)  { create_mount_resource('/var/log') }
    let(:var_file) { create_file_resource('/var') }
    let(:log_file) { create_file_resource('/var/log') }
    let(:puppet_file) { create_file_resource('/var/log/puppet') }
    let(:opt_file) { create_file_resource('/opt/var/puppet') }

    before(:each) do
      create_catalog(root_mount, var_mount, log_mount, var_file, log_file, puppet_file, opt_file)
    end

    it 'adds no autorequires for the root mount' do
      expect(root_mount.autorequire).to be_empty
    end

    it 'adds the parent autorequire and the file autorequire for a mount with one parent' do
      parent_relationship = var_mount.autorequire[0]

      expect(var_mount.autorequire.size).to eq(1)

      expect(parent_relationship.source).to eq root_mount
      expect(parent_relationship.target).to eq var_mount
    end

    it 'adds both parent autorequires and the file autorequire for a mount with two parents' do
      grandparent_relationship = log_mount.autorequire[0]
      parent_relationship = log_mount.autorequire[1]

      expect(log_mount.autorequire.size).to eq(2)

      expect(grandparent_relationship.source).to eq root_mount
      expect(grandparent_relationship.target).to eq log_mount

      expect(parent_relationship.source).to eq var_mount
      expect(parent_relationship.target).to eq log_mount
    end

    it 'adds the child autobefore for a mount with one file child' do
      child_relationship = log_mount.autobefore[0]

      expect(log_mount.autobefore.size).to eq(1)

      expect(child_relationship.source).to eq log_mount
      expect(child_relationship.target).to eq puppet_file
    end

    it 'adds both child autobefores for a mount with two file children' do
      child_relationship = var_mount.autobefore[0]
      grandchild_relationship = var_mount.autobefore[1]

      expect(var_mount.autobefore.size).to eq(2)

      expect(child_relationship.source).to eq var_mount
      expect(child_relationship.target).to eq log_file

      expect(grandchild_relationship.source).to eq var_mount
      expect(grandchild_relationship.target).to eq puppet_file
    end
  end
end
