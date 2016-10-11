require 'spec_helper'

provider_class = Puppet::Type.type(:logical_volume).provider(:lvm)

describe provider_class do

  before do
    @resource = stub_everything("resource")
    @provider = provider_class.new(@resource)
  end

  lvs_output = <<-EOS
  LV      VG       Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  lv_root VolGroup -wi-ao----  18.54g
  lv_swap VolGroup -wi-ao---- 992.00m
  EOS

  describe 'self.instances' do
    before :each do
      @provider.class.stubs(:lvs).returns(lvs_output)
    end

    it 'returns an array of logical volumes' do
      logical_volumes = @provider.class.instances.collect {|x| x.name }

      expect(logical_volumes).to include('lv_root','lv_swap')
    end
  end

  describe 'when creating' do
    context 'with size' do
      it "should execute 'lvcreate' with a '--size' option" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:size).returns('1g').at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
        @provider.create
      end
    end
    context 'with size and type' do
      it "should execute 'lvcreate' with a '--size' option" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:size).returns('1g').at_least_once
        @resource.expects(:[]).with(:type).returns('linear').at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', '--type', 'linear', 'myvg')
        @provider.create
      end
    end
    context 'with initial_size' do
      it "should execute 'lvcreate' with a '--size' option" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:initial_size).returns('1g').at_least_once
        @resource.expects(:[]).with(:size).returns(nil).at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
        @provider.create
      end
    end
     context 'without size and without extents' do
      it "should execute 'lvcreate' without a '--size' option or a '--extents' option" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:size).returns(nil).at_least_once
        @resource.expects(:[]).with(:initial_size).returns(nil).at_least_once
        @resource.expects(:[]).with(:extents).returns(nil).at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--extents', '100%FREE', 'myvg')
        @provider.create
      end
    end
    context 'with extents' do
      it "should execute 'lvcreate' with a '--extents' option" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:size).returns('1g').at_least_once
        @resource.expects(:[]).with(:extents).returns('80%vg').at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', '--extents', '80%vg', 'myvg')
        @provider.create
      end
    end
    context 'without extents' do
      it "should execute 'lvcreate' without a '--extents' option" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:size).returns('1g').at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
        @provider.create
      end
    end
    context 'with initial_size and mirroring' do
      it "should execute 'lvcreate' with '--size' and '--mirrors' and '--mirrorlog' options" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:initial_size).returns('1g').at_least_once
        @resource.expects(:[]).with(:mirror).returns('1').at_least_once
        @resource.expects(:[]).with(:mirrorlog).returns('core').at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', '--mirrors', '1', '--mirrorlog', 'core', 'myvg')
        @provider.create
      end
    end
    context 'with persistent minor block device' do
      it "should execute 'lvcreate' with '--persistent y' and '--minor 100' option" do
        @resource.expects(:[]).with(:name).returns('mylv')
        @resource.expects(:[]).with(:volume_group).returns('myvg')
        @resource.expects(:[]).with(:size).returns('1g').at_least_once
        @resource.expects(:[]).with(:persistent).returns(:true).at_least_once
        @resource.expects(:[]).with(:minor).returns('100').at_least_once
        @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', '--persistent', 'y', '--minor', '100', 'myvg')
        @provider.create
      end
    end
  end

  describe "when modifying" do
    context "with a larger size" do
      context "in extent portions" do
        it "should execute 'lvextend'" do
          @resource.expects(:[]).with(:name).returns('mylv').at_least_once
          @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
          @resource.expects(:[]).with(:size).returns('1g').at_least_once
          @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
          @provider.create
          @provider.expects(:lvs).with('--noheading', '--unit', 'g', '/dev/myvg/mylv').returns(' 1.00g').at_least_once
          @provider.expects(:lvs).with('--noheading', '-o', 'vg_extent_size', '--units', 'k', '/dev/myvg/mylv').returns(' 1000.00k')
          @provider.expects(:lvextend).with('-L', '2000000k', '/dev/myvg/mylv').returns(true)
          @provider.expects(:blkid).with('/dev/myvg/mylv')
          @provider.size = '2000000k'
        end
        context "with resize_fs flag" do
          it "should execute 'blkid' if resize_fs is set to true" do
            @resource.expects(:[]).with(:name).returns('mylv').at_least_once
            @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
            @resource.expects(:[]).with(:size).returns('1g').at_least_once
            @resource.expects(:[]).with(:resize_fs).returns('true').at_least_once
            @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
            @provider.create
            @provider.expects(:lvs).with('--noheading', '--unit', 'g', '/dev/myvg/mylv').returns(' 1.00g').at_least_once
            @provider.expects(:lvs).with('--noheading', '-o', 'vg_extent_size', '--units', 'k', '/dev/myvg/mylv').returns(' 1000.00k')
            @provider.expects(:lvextend).with('-L', '2000000k', '/dev/myvg/mylv').returns(true)
            @provider.expects(:blkid).with('/dev/myvg/mylv')
            @provider.size = '2000000k'
          end
          it "should not execute 'blkid' if resize_fs is set to false" do
            @resource.expects(:[]).with(:name).returns('mylv').at_least_once
            @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
            @resource.expects(:[]).with(:size).returns('1g').at_least_once
            @resource.expects(:[]).with(:resize_fs).returns('false').at_least_once
            @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
            @provider.create
            @provider.expects(:lvs).with('--noheading', '--unit', 'g', '/dev/myvg/mylv').returns(' 1.00g').at_least_once
            @provider.expects(:lvs).with('--noheading', '-o', 'vg_extent_size', '--units', 'k', '/dev/myvg/mylv').returns(' 1000.00k')
            @provider.expects(:lvextend).with('-L', '2000000k', '/dev/myvg/mylv').returns(true)
            @provider.expects(:blkid).with('/dev/myvg/mylv').never
            @provider.size = '2000000k'
          end
        end
      end
      context "not in extent portions" do
        it "should raise an exception" do
          @resource.expects(:[]).with(:name).returns('mylv').at_least_once
          @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
          @resource.expects(:[]).with(:size).returns('1g').at_least_once
          @resource.expects(:[]).with(:extents).returns(nil).at_least_once
          @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
          @provider.create
          @provider.expects(:lvs).with('--noheading', '--unit', 'g', '/dev/myvg/mylv').returns(' 1.00g').at_least_once
          @provider.expects(:lvs).with('--noheading', '-o', 'vg_extent_size', '--units', 'k', '/dev/myvg/mylv').returns(' 1000.00k')
          proc { @provider.size = '1.15g' }.should raise_error(Puppet::Error, /extent/)
        end
      end
    end
    context "with a smaller size" do
      context "without size_is_minsize set to false" do
        it "should raise an exception" do
          @resource.expects(:[]).with(:name).returns('mylv').at_least_once
          @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
          @resource.expects(:[]).with(:size).returns('1g').at_least_once
          @resource.expects(:[]).with(:size_is_minsize).returns(:false).at_least_once
          @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
          @provider.create
          @provider.expects(:lvs).with('--noheading', '--unit', 'g', '/dev/myvg/mylv').returns(' 1.00g').at_least_once
          @provider.expects(:lvs).with('--noheading', '-o', 'vg_extent_size', '--units', 'k', '/dev/myvg/mylv').returns(' 1000.00k')
          proc { @provider.size = '1m' }.should raise_error(Puppet::Error, /manual/)
        end
      end
      context "with size_is_minsize set to true" do
        it "should not raise an exception and print info message" do
          Puppet::Util::Log.level = :info
          Puppet::Util::Log.newdestination(:console)
          @resource.expects(:[]).with(:name).returns('mylv').at_least_once
          @resource.expects(:[]).with(:volume_group).returns('myvg').at_least_once
          @resource.expects(:[]).with(:size).returns('1g').at_least_once
          @resource.expects(:[]).with(:size_is_minsize).returns(:true).at_least_once
          @provider.expects(:lvcreate).with('-n', 'mylv', '--size', '1g', 'myvg')
          @provider.create
          @provider.expects(:lvs).with('--noheading', '--unit', 'g', '/dev/myvg/mylv').returns(' 1.00g').at_least_once
          @provider.expects(:lvs).with('--noheading', '-o', 'vg_extent_size', '--units', 'k', '/dev/myvg/mylv').returns(' 1000.00k')
          proc { @provider.size = '1m' }.should output(/already/).to_stdout
        end
      end
    end
  end

  describe 'when destroying' do
    it "should execute 'dmsetup' and 'lvremove'" do
      @resource.expects(:[]).with(:volume_group).returns('myvg').twice
      @resource.expects(:[]).with(:name).returns('mylv').twice
      @provider.expects(:dmsetup).with('remove', 'myvg-mylv')
      @provider.expects(:lvremove).with('-f', '/dev/myvg/mylv')
      @provider.destroy
    end
    it "should execute 'dmsetup' and 'lvremove' and properly escape names with dashes" do
      @resource.expects(:[]).with(:volume_group).returns('my-vg').twice
      @resource.expects(:[]).with(:name).returns('my-lv').twice
      @provider.expects(:dmsetup).with('remove', 'my--vg-my--lv')
      @provider.expects(:lvremove).with('-f', '/dev/my-vg/my-lv')
      @provider.destroy
    end
  end
end
