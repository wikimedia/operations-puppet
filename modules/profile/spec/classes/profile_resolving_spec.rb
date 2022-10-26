require_relative '../../../../rake_modules/spec_helper'
describe 'profile::resolving' do
  on_supported_os(WMFConfig.test_on(10)).each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(
          {
            'networking' => facts[:networking].merge({'domain' => 'example.com'}),
            'wmcs_project' => 'fun',
          }
        )
      end
      let(:params){ {'nameservers' => ['192.0.2.53']}}
      context "default" do
        it { is_expected.to compile.with_all_deps }
        it "contains a correct resolv.conf"  do
          is_expected.to contain_file('/etc/resolv.conf')
            .with_owner('root')
            .with_group('root')
            .with_mode('0444')
            .with_content(/search.*example.com/)
            .with_content(/options timeout:1 attempts:3 ndots:1/)
            .with_content(/nameserver 192.0.2.53/)
        end
      end
      context "when realm is labs" do
        let(:params) do
          super().merge({
            disable_resolvconf: true,
            disable_dhcpupdates: true,
          })
        end
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/sbin/resolvconf') }
        it { is_expected.to contain_file('/etc/dhcp/dhclient-enter-hooks.d/nodnsupdate') }
        it "contains a correct resolv.conf" do
          is_expected.to contain_file('/etc/resolv.conf')
            .with_content(/search.*example.com/)
            .with_content(/options timeout:1 attempts:3 ndots:1/)
            .with_content(/nameserver 192.0.2.53/)
        end
      end
    end
  end
end
