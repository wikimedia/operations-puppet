require_relative '../../../../rake_modules/spec_helper'

describe 'install_server::preseed_server', :type => :class do
  on_supported_os(WMFConfig.test_on(12, 12)).each do |os, facts|
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
            'public1-603-eqsin' => {
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

      it "Creates /srv/autoinstall directory" do
        is_expected.to contain_file('/srv/autoinstall').with({
          'ensure' => 'directory',
          'mode'   => '0444',
          'recurse' => 'true',
        })
      end

      it "Creates /srv/autoinstall/subnects directory" do
        is_expected.to contain_file('/srv/autoinstall/subnets').with({
          'ensure' => 'directory',
          'mode'   => '0444',
        })
      end

      it "Generates valid netboot.cfg" do
        is_expected.to contain_file('/srv/autoinstall/netboot.cfg')
          .with_ensure('file')
          .with_mode('0444')
          .with_content(%r{10\.192\.0\.1\) echo subnets/private1-a-codfw\.cfg ;; \\\n})
          .with_content(%r{103\.102\.166\.1\) echo subnets/public1-603-eqsin\.cfg ;; \\\n})
          .with_content(%r{alert\*\) echo partman/standard\.cfg partman/raid1-2dev\.cfg ;; \\\n})
          .with_content(%r{auth\[12\]\*\) echo partman/standard\.cfg partman/raid1-2dev\.cfg ;; \\\n})
      end

      it "Creates private network with .wmnet domain and web_proxy" do
        is_expected.to contain_file('/srv/autoinstall/subnets/private1-a-codfw.cfg')
          .with_ensure('file')
          .with_mode('0444')
          .with_content(%r{d-i\tnetcfg/get_domain\tstring\tcodfw.wmnet})
          .with_content(%r{d-i\tnetcfg/get_netmask\tstring\t255.255.252.0})
          .with_content(%r{d-i\tnetcfg/get_gateway\tstring\t10.192.0.1})
          .with_content(%r{d-i\tmirror/http/proxy\tstring\thttp://webproxy.codfw.wmnet:8080})
      end

      it "Creates public network with wikimedia.org domain and without web proxy" do
        is_expected.to contain_file('/srv/autoinstall/subnets/public1-603-eqsin.cfg')
          .with_ensure('file')
          .with_mode('0444')
          .with_content(%r{d-i\tnetcfg/get_domain\tstring\twikimedia.org})
          .with_content(%r{d-i\tnetcfg/get_netmask\tstring\t255.255.255.240})
          .with_content(%r{d-i\tnetcfg/get_gateway\tstring\t103.102.166.1})
          .without_content(%r{d-i\tmirror/http/proxy\tstring})
      end

      it "Symlinks preseed.cfg to netboot.cfg" do
        is_expected.to contain_file('/srv/autoinstall/preseed.cfg').with({
          'ensure' => 'link',
          'target' => '/srv/autoinstall/netboot.cfg',
        })
      end
    end
  end
end
