require 'spec_helper'

describe 'base::resolving' do
    it 'requires $nameservers' do
        should compile.and_raise_error(
            /Variable \$nameservers is not defined!/)
    end
    context "when \$::nameservers are defined" do
      let(:facts) { {'domain' => 'example.com'} }
      let(:node_params){ {'nameservers' => ['1.2.3.4'], 'realm' => 'production'}}
      it { is_expected.to compile.with_all_deps }
      it "contains a correct resolv.conf"  do
        is_expected.to contain_file('/etc/resolv.conf')
                         .with_owner('root')
                         .with_group('root')
                         .with_mode('0444')
        content = catalogue.resource('file', '/etc/resolv.conf').send(:parameters)[:content]

        expect(content).to match(/search example.com\noptions timeout:1 attempts:3\nnameserver 1.2.3.4\n/)
      end
      context "when nameservers are overridden" do
        let(:params) { {'nameservers' => ['2.2.2.2']}}
        it "nameserver is changed in resolv.conf" do
          content = catalogue.resource('file', '/etc/resolv.conf').send(:parameters)[:content]

          expect(content).to match(/search example.com\noptions timeout:1 attempts:3\nnameserver 2.2.2.2\n/)
        end
      end
    end
    context "when realm is labs" do
      let(:facts) { {'domain' => 'example.com', 'labsproject' => 'fun' } }
      let(:node_params){
        {
          'nameservers' => ['1.2.3.4'],
          'realm' => 'labs',
          'site' => 'testdc',
        }
      }
      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_file('/sbin/resolvconf').with_source('puppet:///modules/base/resolv/resolvconf.dummy') }
      it { is_expected.to contain_file('/etc/dhcp/dhclient-enter-hooks.d/nodnsupdate').with_source('puppet:///modules/base/resolv/nodnsupdate')}
      it "contains a correct resolv.conf" do
        content = catalogue.resource('file', '/etc/resolv.conf').send(:parameters)[:content]

        expect(content).to match(/search fun.testdc.foo.bar testdc.foo.bar \nnameserver 1.2.3.4\noptions timeout:2 ndots:1/)
      end
    end
end
