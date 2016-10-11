require 'spec_helper'

provider_class = Puppet::Type.type(:filesystem).provider(:lvm)

describe provider_class do
  before do
    @resource = stub("resource")
    @provider = provider_class.new(@resource)
  end

  describe 'when creating' do
    it "should execute the correct filesystem command" do
      @resource.expects(:[]).with(:name).returns('/dev/myvg/mylv')
      @resource.expects(:[]).with(:fs_type).returns('ext4')
      @resource.expects(:[]).with(:options)
      @provider.expects(:execute).with(['mkfs.ext4', '/dev/myvg/mylv'])
      @resource.expects(:[]).with(:mkfs_cmd)
      @provider.create
    end
    it "should include the supplied filesystem options" do
      @resource.expects(:[]).with(:name).returns('/dev/myvg/mylv')
      @resource.expects(:[]).with(:fs_type).returns('ext4')
      @resource.expects(:[]).with(:options).returns('-b 4096 -E stride=32,stripe-width=64').twice
      @provider.expects(:execute).with(['mkfs.ext4', '/dev/myvg/mylv', ['-b', '4096', '-E', 'stride=32,stripe-width=64']])
      @resource.expects(:[]).with(:mkfs_cmd)
      @provider.create
    end
    it "should include -q for reiserfs" do
      @resource.expects(:[]).with(:name).returns('/dev/myvg/mylv')
      @resource.expects(:[]).with(:fs_type).returns('reiserfs')
      @resource.expects(:[]).with(:options).returns('-b 4096 -E stride=32,stripe-width=64').twice
      @provider.expects(:execute).with(['mkfs.reiserfs', '/dev/myvg/mylv', '-q', ['-b', '4096', '-E', 'stride=32,stripe-width=64']])
      @resource.expects(:[]).with(:mkfs_cmd)
      @provider.create
    end
    it "should call mkswap for filesystem type swap" do
      @resource.expects(:[]).with(:name).returns('/dev/myvg/mylv')
      @resource.expects(:[]).with(:fs_type).returns('swap')
      @resource.expects(:[]).with(:options)
      @provider.expects(:execute).with(['mkswap', '/dev/myvg/mylv'])
      @resource.expects(:[]).with(:mkfs_cmd)
      @provider.create
    end
    it "should create an ext4 journal correctly" do
      @resource.expects(:[]).with(:name).returns('/dev/myvg/mylv')
      @resource.expects(:[]).with(:fs_type).returns('jbd')
      @resource.expects(:[]).with(:options).returns('-O journal_dev').twice
      @provider.expects(:execute).with(['mkfs.ext4', '/dev/myvg/mylv', ['-O', 'journal_dev']])
      @resource.expects(:[]).with(:mkfs_cmd).returns('mkfs.ext4').twice
      @provider.create
    end
  end

end
