require_relative '../../../../rake_modules/spec_helper'

describe 'install_server::preseed_server', :type => :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts){ facts }
      let(:params) do
        {
          preseed_per_ip: {'208.80.154.1' => 'subnets/public1-a-eqiad.cfg'},
          preseed_per_hostname: {
            'alert*' => ['partman/standard.cfg', 'partman/raid1-2dev.cfg'],
            'auth[12]*' => ['partman/standard.cfg', 'partman/raid1-2dev.cfg'],
          }
        }
      end
      it { is_expected.to compile }
      it do
          is_expected.to contain_file('/srv/autoinstall').with({
              'ensure' => 'directory',
              'mode'   => '0444',
              'recurse' => 'true',
              'links' => 'manage',
          })

          is_expected.to contain_file('/srv/autoinstall/netboot.cfg')
            .with_ensure('present')
            .with_mode('0444')
            .with_content(%r{208\.80\.154\.1\) echo subnets/public1-a-eqiad\.cfg ;;})
            .with_content(%r{alert\*\) echo partman/standard\.cfg partman/raid1-2dev\.cfg ;;})
            .with_content(%r{auth\[12\]\*\) echo partman/standard\.cfg partman/raid1-2dev\.cfg ;;})

          is_expected.to contain_file('/srv/autoinstall/preseed.cfg').with({
              'ensure' => 'link',
              'target' => '/srv/autoinstall/netboot.cfg',
          })
      end
    end
  end
end
