# SPDX-License-Identifier: Apache-2.0
require_relative "../../../../rake_modules/spec_helper"

describe "profile::wmcs::nfs::maintain_dbusers" do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:node_params) {{'_role' => 'wmcs::openstack::eqiad1::control'}}
      let(:params) {{
        "cluster_ip" => "127.0.0.1",
        "section_ports" => {
          "s1" => 3312,
        },
        "variances" => {
          "s12345" => 45,
        },
        "paws_replica_cnf_user" => "paws_user",
        "paws_replica_cnf_password" => "paws_pass",
        "paws_replica_cnf_root_url" => "paws_url",
        "tools_replica_cnf_user" => "tools_user",
        "tools_replica_cnf_password" => "tools_pass",
        "tools_replica_cnf_root_url" => "tools_url",
        "maintain_dbusers_primary" => "im.the.primary",
      }}
      let(:facts) { facts }

      context "It compiles without exploding" do
        it { is_expected.to compile.with_all_deps }
      end

      context "If I'm the primary, my service is present" do
        let(:facts) { super().merge({
          'fqdn' => 'im.the.primary',
        }) }
        it {
          is_expected.to contain_systemd__service("maintain-dbusers")
          .with_ensure("present")
        }
      end

      context "If I'm not the primary, my service is stopped" do
        let(:facts) { super().merge({
          'fqdn' => 'im.not.the.primary',
        }) }
        it {
          is_expected.to contain_systemd__service("maintain-dbusers")
          .with_ensure("absent")
        }
      end
    end
  end
end
