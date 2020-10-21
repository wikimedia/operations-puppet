require_relative '../../../../rake_modules/spec_helper'

describe 'service::node', :type => :define do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts }
      let(:pre_condition) {
        ['class passwords::etcd { $accounts = {"conftool" => "abc"}}',
         'include ::passwords::etcd',
         'class profile::base { $notifications_enabled = "1"}',
         'include ::profile::base'
        ]
      }
      let(:title) { 'my_service_name' }
      context 'when only port is given' do
        let(:params) { { :port => 1234 } }

        it { is_expected.to compile }

        it 'create the appropriate scap target' do
          is_expected.to contain_scap__target('my_service_name/deploy')
                           .with_service_name('my_service_name')
        end
      end
    end
  end
end
