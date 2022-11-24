# SPDX-License-Identifier: Apache-2.0
require_relative "../../../../rake_modules/spec_helper"
describe "profile::toolforge::harbor" do
  on_supported_os(WMFConfig.test_on(11)).each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) {
        {
          "harbor_db_pwd" => "dummy_db_password",
          "harbor_db_host" => "dummy.db.host",
          "harbor_url" => "dummy.harbor.fqdn",
        }
      }
      it { is_expected.to compile.with_all_deps }
    end
  end
end
