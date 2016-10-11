require 'spec_helper'

describe 'lvm', :type => :class do

  describe 'with no parameters' do
    it { should compile.with_all_deps }
  end

  describe 'with volume groups' do
    let(:params) do
      {
        :volume_groups => {
          'myvg' => {
            'physical_volumes' => [ '/dev/sda2', '/dev/sda3', ],
            'logical_volumes'  => {
              'opt'    => {'size' => '20G'},
              'tmp'    => {'size' => '1G' },
              'usr'    => {'size' => '3G' },
              'var'    => {'size' => '15G'},
              'home'   => {'size' => '5G' },
              'backup' => {
                'size'              => '5G',
                'mountpath'         => '/var/backups',
                'mountpath_require' => true
              }
            }
          }
        }
      }
    end

    it { should contain_physical_volume('/dev/sda2') }
    it { should contain_physical_volume('/dev/sda3') }
    it { should contain_volume_group('myvg').with({
      :ensure           => 'present',
      :physical_volumes => [ '/dev/sda2', '/dev/sda3', ]
    }) }

    it { should contain_logical_volume('opt').with( {
      :volume_group => 'myvg',
      :size         => '20G'
    }) }
    it { should contain_filesystem('/dev/myvg/opt') }
    it { should contain_mount('/opt') }

    it { should contain_logical_volume('backup').with({
      :volume_group => 'myvg',
      :size         => '5G'
    }) }
    it { should contain_filesystem('/dev/myvg/backup') }
    it { should contain_mount('/var/backups') }
  end

  describe 'without mount' do
    let(:params) do
      {
        :volume_groups => {
          'myvg' => {
            'physical_volumes' => [ '/dev/sda2', ],
            'logical_volumes'  => {
              'not_mounted' => {
                'size'              => '5G',
                'mounted'           => false,
                'mountpath'         => '/mnt/not_mounted',
                'mountpath_require' => true
              }
            }
          }
        }
      }
    end

    it { should contain_mount('/mnt/not_mounted').with({
        :ensure       => 'present'
    }) }
  end

  describe 'with a swap volume' do
    let(:params) do
      {
        :volume_groups => {
          'myvg' => {
            'physical_volumes' => [ '/dev/sda2', '/dev/sda3', ],
            'logical_volumes'  => {
              'swap'  => {
                'size'    => '20G',
                'fs_type' => 'swap'
              },
              'swap2' => {
                'ensure'  => 'absent',
                'size'    => '20G',
                'fs_type' => 'swap'
              }
            }
          }
        }
      }
    end

    it { should contain_logical_volume('swap').with({
      :volume_group => 'myvg',
      :size         => '20G'
    }) }
    it { should contain_filesystem('/dev/myvg/swap').with({
      :fs_type => 'swap'
    }) }
    it { should contain_mount('/dev/myvg/swap').with({
      :name   => 'swap_/dev/myvg/swap',
      :ensure => 'present',
      :fstype => 'swap',
      :pass   => 0,
      :dump   => 0
    }) }
    it { should contain_exec("swapon for '/dev/myvg/swap'") }
    it { should_not contain_exec("ensure mountpoint 'swap_/dev/myvg/swap' exists") }

    it { should contain_exec("swapoff for '/dev/myvg/swap2'") }
    it { should_not contain_exec("ensure mountpoint 'swap_/dev/myvg/swap2' exists") }
  end
end
