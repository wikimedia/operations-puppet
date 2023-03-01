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
      describe 'compiles without errors' do
        it { is_expected.to compile.with_all_deps }
      end

      describe 'adds the given robot accounts and cinder_attached if passed' do
        let(:params) {
          super().merge({
            "cinder_attached" => true,
            "robot_accounts" => {
              "robot1" => {
                "password": "robot1pass",
              },
              "robot2" => {
                "password": "robot2pass",
              },
            }
          })
        }

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file('/srv/ops/harbor/harbor.yml')
          .with_content(/robot1:/)
          .with_content(/password: "robot1pass"/)
          .with_content(/robot2:/)
          .with_content(/password: "robot2pass"/)
        }
      end
    end
  end
end
