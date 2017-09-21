require 'spec_helper'

describe 'service::node', :type => :define do
  let(:pre_condition) {
    'class passwords::etcd { $accounts = {}}'
  }
  let(:title) { 'my_service_name' }
  let(:facts) { { :initsystem => 'systemd' } }
  let(:node_params) { {'cluster' => 'test', 'site' => 'eqiad'} }
  let(:pre_condition) { """
class profile::base {
      $notifications_enabled = '1'
}
include ::profile::base
""" }
  context 'when only port is given' do
    let(:params) { { :port => 1234 } }

    it { is_expected.to compile }

    it 'create the appropriate scap target' do
      is_expected.to contain_scap__target('my_service_name/deploy')
                       .with_service_name('my_service_name')
    end
  end
end
