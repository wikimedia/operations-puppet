require 'spec_helper'
test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9'],
    }
  ]
}

describe 'service::node', :type => :define do
  on_supported_os(test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) do
        facts.merge({initsystem: 'systemd'})
      end

      let(:pre_condition) {
        ['class passwords::etcd { $accounts = {}}',
         'include ::passwords::etcd',
         'class profile::base { $notifications_enabled = "1"}',
         'include ::profile::base'
        ]
      }
      let(:title) { 'my_service_name' }
      let(:node_params) { {'cluster' => 'test', 'site' => 'eqiad', 'realm' => 'production'} }
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
