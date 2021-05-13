require_relative '../../../../rake_modules/spec_helper'

describe 'base::resolving' do
    let(:facts) { { 'domain' => 'example.com', 'labsproject' => 'fun' } }
    let(:params){ {'nameservers' => ['192.0.2.53']}}
    context "default" do
      let(:node_params){ {'realm' => 'production'}}
      it { is_expected.to compile.with_all_deps }
      it "contains a correct resolv.conf"  do
        is_expected.to contain_file('/etc/resolv.conf')
          .with_owner('root')
          .with_group('root')
          .with_mode('0444')
          .with_content(/search example.com/)
          .with_content(/options timeout:1 attempts:3 ndots:1/)
          .with_content(/nameserver 192.0.2.53/)
      end
    end
    context "when realm is labs" do
      let(:node_params){
        {
          'realm' => 'labs',
          'site' => 'testdc',
        }
      }
      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_file('/sbin/resolvconf').with_source('puppet:///modules/base/resolv/resolvconf.dummy') }
      it { is_expected.to contain_file('/etc/dhcp/dhclient-enter-hooks.d/nodnsupdate').with_source('puppet:///modules/base/resolv/nodnsupdate')}
      it "contains a correct resolv.conf" do
        is_expected.to contain_file('/etc/resolv.conf')
          .with_content(/search example.com/)
          .with_content(/options timeout:1 attempts:3 ndots:1/)
          .with_content(/nameserver 192.0.2.53/)
      end
    end
end
