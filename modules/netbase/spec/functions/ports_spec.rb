# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'netbase::ports' do
  it { is_expected.to run }
  it 'test single service as string' do
    is_expected.to run.with_params(22)
      .and_return({"ssh" => {"protocols" => ["tcp"], "port" => 22, "description" => "SSH Remote Login Protocol"}})
  end
  it 'test single service as array' do
    is_expected.to run.with_params([22])
      .and_return({"ssh" => {"protocols" => ["tcp"], "port" => 22, "description" => "SSH Remote Login Protocol"}})
  end
  it 'test enty with multiple protocols' do
    is_expected.to run.with_params([53])
      .and_return({"domain" => {"protocols" => ["tcp", "udp"], "port" => 53, "description" => "Domain Name Server"}})
  end
  it 'test multiple args' do
    is_expected.to run.with_params([22, 53])
      .and_return({
        "ssh" => {"protocols" => ["tcp"], "port" => 22, "description" => "SSH Remote Login Protocol"},
        "domain" => {"protocols" => ["tcp", "udp"], "port" => 53, "description" => "Domain Name Server"}})
  end
  it 'test aliases' do
    is_expected.to run.with_params([88])
      .and_return({
        "kerberos" => {
          "protocols" => ["tcp", "udp"],
          "port" => 88,
          "description" => "Kerberos v5",
          "aliases" => ["kerberos5", "krb5", "kerberos-sec"]
        }
      })
  end
end
