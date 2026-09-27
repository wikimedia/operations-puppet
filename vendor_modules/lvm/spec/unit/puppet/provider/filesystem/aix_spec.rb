# frozen_string_literal: true

require 'spec_helper'

provider_class = Puppet::Type.type(:filesystem).provider(:aix)

describe provider_class do
  let(:resource) { Puppet::Type.type(:filesystem).new(name: '/mnt/data') }
  let(:provider) { provider_class.new(resource) }

  describe '#exists?' do
    it 'returns true when lsfs exits successfully' do
      status = stub('status', success?: true)
      Open3.expects(:popen3).with('lsfs /mnt/data').returns([nil, nil, nil, stub('thread', value: status)])
      expect(provider.exists?).to be true
    end

    it 'returns false when lsfs exits with a non-zero status' do
      status = stub('status', success?: false)
      Open3.expects(:popen3).with('lsfs /mnt/data').returns([nil, nil, nil, stub('thread', value: status)])
      expect(provider.exists?).to be false
    end
  end

  describe '#create' do
    it 'passes fs_type and mount point to crfs' do
      resource[:fs_type] = 'jfs2'
      provider.expects(:crfs).with('-v', 'jfs2', '-m', '/mnt/data')
      provider.create
    end

    it 'maps ag_size to the crfs -a ag flag' do
      resource[:ag_size] = '8'
      provider.expects(:crfs).with('-a', 'ag=8', '-m', '/mnt/data')
      provider.create
    end

    it 'converts :true attribute values to "yes"' do
      # large_files has no entry in attribute_flag's rename map (only large_file does),
      # so the attribute name passes through as-is: "-a large_files=yes"
      resource[:large_files] = :true
      provider.expects(:crfs).with('-a', 'large_files=yes', '-m', '/mnt/data')
      provider.create
    end

    it 'converts :false attribute values to "no"' do
      resource[:mountguard] = :false
      provider.expects(:crfs).with('-a', 'mountguard=no', '-m', '/mnt/data')
      provider.create
    end

    it 'passes volume_group as the -g flag' do
      resource[:volume_group] = 'myvg'
      provider.expects(:crfs).with('-m', '/mnt/data', '-g', 'myvg')
      provider.create
    end

    it 'passes atboot as the -A flag, converting :true to "yes"' do
      resource[:atboot] = :true
      provider.expects(:crfs).with('-m', '/mnt/data', '-A', 'yes')
      provider.create
    end

    context 'when size is set and already matches the current filesystem size' do
      it 'does not call size= after crfs' do
        resource[:size] = '1G'
        provider.stubs(:size).returns('1G')
        provider.expects(:crfs).with('-a', 'size=1G', '-m', '/mnt/data')
        provider.expects(:size=).never
        provider.create
      end
    end

    context 'when size is set but does not match the current filesystem size' do
      it 'calls size= after crfs to sync the filesystem' do
        resource[:size] = '2G'
        provider.stubs(:size).returns('1G')
        provider.expects(:crfs).with('-a', 'size=2G', '-m', '/mnt/data')
        provider.expects(:size=).with('2G')
        provider.create
      end
    end
  end

  describe '#size=' do
    it 'calls chfs with the size attribute and mount point' do
      resource[:size] = '2G'
      provider.expects(:chfs).with('-a', 'size=2G', '/mnt/data')
      provider.size = '2G'
    end
  end

  describe '#size' do
    # lsfs -q output columns (whitespace-separated):
    #   Name  Nodename  MountPt  VFS  Size  Options  Auto  Accounting
    # The provider matches elements[2] against @resource[:name] and reads elements[4] as blocks.

    before(:each) do
      resource[:size] = '1G'
      provider.stubs(:pp_size).returns(4) # ppsize = 4 * 1024 * 2 = 8192 blocks
    end

    it 'returns the resource size when the reported block count matches' do
      # 1G = 2_097_152 blocks; blk_roundup(2_097_152) with ppsize=8192 stays 2_097_152
      lsfs_line = "/dev/myvg/mylv  --  /mnt/data  jfs2  2097152  rw  yes  no\n"
      Open3.expects(:popen3).with('lsfs -q /mnt/data').yields(nil, [lsfs_line], nil)
      expect(provider.size).to eq('1G')
    end

    it 'returns the current size when the reported block count differs from requested' do
      # 3G = 6_291_456 blocks; blk_to_val(6_291_456, 'G') = '3G'
      lsfs_line = "/dev/myvg/mylv  --  /mnt/data  jfs2  6291456  rw  yes  no\n"
      Open3.expects(:popen3).with('lsfs -q /mnt/data').yields(nil, [lsfs_line], nil)
      expect(provider.size).to eq('3G')
    end

    it 'returns "0G" when no lsfs line matches the mount point' do
      lsfs_line = "/dev/other/lv  --  /mnt/other  jfs2  2097152  rw  yes  no\n"
      Open3.expects(:popen3).with('lsfs -q /mnt/data').yields(nil, [lsfs_line], nil)
      expect(provider.size).to eq('0G')
    end
  end

  describe '#parse_boolean' do
    it 'converts :true to "yes"' do
      expect(provider.parse_boolean(:true)).to eq('yes')
    end

    it 'converts :false to "no"' do
      expect(provider.parse_boolean(:false)).to eq('no')
    end

    it 'passes through non-boolean values unchanged' do
      expect(provider.parse_boolean('jfs2')).to eq('jfs2')
    end
  end

  describe '#val_to_blk' do
    it 'converts megabytes to 512-byte blocks' do
      expect(provider.val_to_blk('4M')).to eq(8192)
    end

    it 'converts gigabytes to 512-byte blocks' do
      expect(provider.val_to_blk('2G')).to eq(4_194_304)
    end

    it 'returns the integer value for bare numbers (no unit suffix)' do
      expect(provider.val_to_blk('512')).to eq(512)
    end
  end

  describe '#blk_to_val' do
    it 'converts 512-byte blocks to megabytes' do
      expect(provider.blk_to_val(8192, 'M')).to eq('4M')
    end

    it 'converts 512-byte blocks to gigabytes' do
      expect(provider.blk_to_val(2_097_152, 'G')).to eq('1G')
    end

    it 'returns the raw block count when no unit is given' do
      expect(provider.blk_to_val(512)).to eq(512)
    end
  end

  describe '#blk_roundup' do
    before(:each) { provider.stubs(:pp_size).returns(4) } # ppsize = 4 * 1024 * 2 = 8192 blocks

    it 'returns the block count unchanged when already aligned to a PP boundary' do
      expect(provider.blk_roundup(8192)).to eq(8192)
    end

    it 'rounds up to the next PP boundary' do
      expect(provider.blk_roundup(8193)).to eq(16_384)
    end
  end

  describe '#pp_size' do
    it 'queries lsvg for the volume_group and returns the PP size in MB' do
      resource[:volume_group] = 'myvg'
      # `lsvg myvg | grep 'PP SIZE'` returns one line; split on whitespace gives index 5 as the number
      lsvg_line = "VG STATE:         active         PP SIZE:         4 megabyte(s)\n"
      Open3.expects(:capture2).with("lsvg myvg | /bin/grep 'PP SIZE'").returns([lsvg_line, nil])
      expect(provider.pp_size).to eq(4)
    end

    it 'defaults to rootvg when volume_group is not set' do
      lsvg_line = "VG STATE:         active         PP SIZE:         8 megabyte(s)\n"
      Open3.expects(:capture2).with("lsvg rootvg | /bin/grep 'PP SIZE'").returns([lsvg_line, nil])
      expect(provider.pp_size).to eq(8)
    end
  end
end
