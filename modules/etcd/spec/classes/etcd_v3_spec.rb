require_relative '../../../../rake_modules/spec_helper'

default_file = '/etc/default/etcd'

describe 'etcd::v3' do
    on_supported_os(WMFConfig.test_on(9, 9)).each do |os, facts|
        context "On #{os}" do
            let(:pre_condition) do
              'class profile::base { $notifications_enabled = "1"}
              include profile::base'
            end
            let(:facts) { facts.merge({ networking: { ip: '1.1.1.1'} }) }

            # Srv discovery test
            context "srv discovery" do
                let(:params) { {:srv_dns => '_etcd._tcp.example.org'} }
                it { is_expected.to contain_file(default_file)
                    .with_content(/ETCD_DISCOVERY_SRV/)
                }
            end
            context "no clustering set" do
                it {
                    is_expected.to compile
                    .and_raise_error(/We need either the domain name for DNS discovery or an explicit peers list/)
                }
            end
            context "with a peer list" do
                let :params do
                    { peers_list: 'abdef' }
                end
                it {
                    is_expected.to contain_file(default_file)
                        .with_content(/ETCD_INITIAL_CLUSTER="abdef"/)
                }
                it {
                    is_expected.to contain_service('etcd')
                        .with_ensure('running')
                }
            end
        end
    end
end
