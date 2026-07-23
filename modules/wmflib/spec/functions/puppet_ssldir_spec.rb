# SPDX-License-Identifier: Apache-2.0
require_relative "../../../../rake_modules/spec_helper"

describe "puppet_ssldir" do
  context do
    let(:facts) { { "networking" => { "fqdn" => "bubbles.com" } } }
    it "should return the ssl dir" do
      should run.and_return("/var/lib/puppet/ssl")
    end
  end
end
