require_relative '../../../../rake_modules/spec_helper'

describe 'profile::wmcs::services::postgres::osm_primary' do
  on_supported_os(WMFConfig.test_on(10, 10)).each do |os, facts|
    context "on #{os}" do
      base_params = {
        'osm_password' => 'osmdummypass',
        'kolossos_password' => 'kolossosdummypass',
        'aude_password' => 'audedummypass',
        'planemad_password' => 'planemaddummypass',
      }
      let(:facts) { facts.merge({
        'fqdn' => 'dummyhost1',
      }) }
      let(:node_params) {{ '_role' => 'wmcs::services::postgres::osm_primary' }}
      let(:params) { base_params }
      it { is_expected.to compile.with_all_deps }
    end
  end
end
