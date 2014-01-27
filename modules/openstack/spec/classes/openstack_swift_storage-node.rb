require 'spec_helper'

describe 'openstack::swift::storage-node' do

  let :params do
    {
      :swift_zone        => '1',
      :storage_devices   => '1',
    }
  end

  let :facts do
    { :ipaddress_eth0 => '192.168.1.2' }
  end

  it 'should configure using the default values' do
    should contain_class('swift').with(
      :swift_hash_suffix     => 'swift_secret',
      :package_ensure        => 'present',
    )
    should contain_define('swift::storage::loopback').with(
      :base_dir         => '/srv/loopback-device',
      :mnt_base_dir     => '/srv/node',
    )
    should contain_class('swift::storage::all').with(
      :storage_local_net_ip     => '192.168.1.2',
    )
  end

  describe 'when setting up dsik for storage_type' do
    before do
      params.merge!(
        :storage_type       => 'disk',
        :storage_devices    => 'sda',
      )
    end
  it 'should configure using the configured values' do
    should contain_class('swift').with(
      :swift_hash_suffix     => 'swift_secret',
      :package_ensure        => 'present',
    )
    should contain_define('swift::storage::disk').with(
      :mnt_base_dir     => '/srv/node',
      :byte_size        => '1024',
    )
    should contain_class('swift::storage::all').with(
      :storage_local_net_ip     => '192.168.1.2',
    )
  end

end
