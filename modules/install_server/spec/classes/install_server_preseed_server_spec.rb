require_relative '../../../../rake_modules/spec_helper'

describe 'install_server::preseed_server', :type => :class do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts){ facts }
      let(:params) do
        {
          preseed_subnets: {
            'private1-a-codfw' => {
              'subnet_gateway' => '10.192.0.1',
              'subnet_mask' => '255.255.252.0',
              'public_subnet' => false,
              'datacenter_name' => 'codfw',
            },
            'public1-eqsin' => {
              'subnet_gateway' => '103.102.166.1',
              'subnet_mask' => '255.255.255.240',
              'public_subnet' => true,
              'datacenter_name' => 'eqsin',
            }
          },
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
          })

          is_expected.to contain_file('/srv/autoinstall/subnets').with({
              'ensure' => 'directory',
              'mode'   => '0444',
          })

          is_expected.to contain_file('/srv/autoinstall/netboot.cfg')
            .with_ensure('file')
            .with_mode('0444')
            .with_content(%r{10\.192\.0\.1\) echo subnets/private1-a-codfw\.cfg ;; \\\n})
            .with_content(%r{103\.102\.166\.1\) echo subnets/public1-eqsin\.cfg ;; \\\n})
            .with_content(%r{alert\*\) echo partman/standard\.cfg partman/raid1-2dev\.cfg ;; \\\n})
            .with_content(%r{auth\[12\]\*\) echo partman/standard\.cfg partman/raid1-2dev\.cfg ;; \\\n})

          is_expected.to contain_file('/srv/autoinstall/subnets/private1-a-codfw.cfg')
            .with_ensure('file')
            .with_mode('0444')
            .with_content(%r{d-i	netcfg/get_domain	string	codfw.wmnet})
            .with_content(%r{d-i	netcfg/get_netmask	string	255.255.252.0})
            .with_content(%r{d-i	netcfg/get_gateway	string	10.192.0.1})
            .with_content(%r{d-i	mirror/http/proxy	string	http://webproxy.codfw.wmnet:8080})

          is_expected.to contain_file('/srv/autoinstall/subnets/public1-eqsin.cfg')
            .with_ensure('file')
            .with_mode('0444')
            .with_content(%r{d-i	netcfg/get_domain	string	wikimedia.org})
            .with_content(%r{d-i	netcfg/get_netmask	string	255.255.255.240})
            .with_content(%r{d-i	netcfg/get_gateway	string	103.102.166.1})
            .without_content(%r{d-i	mirror/http/proxy	string})

          is_expected.to contain_file('/srv/autoinstall/preseed.cfg').with({
              'ensure' => 'link',
              'target' => '/srv/autoinstall/netboot.cfg',
          })
      end
    end
  end
end
