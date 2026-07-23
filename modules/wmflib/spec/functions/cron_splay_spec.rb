# SPDX-License-Identifier: Apache-2.0
require_relative "../../../../rake_modules/spec_helper"

describe "cron_splay" do
  hosts = %w[foo1.com bar1.com bubbles.com]
  context do
    let(:facts) { { "networking" => { "fqdn" => "bubbles.com" } } }
    it "should return a weekly splay for this host" do
      should run.with_params(hosts, "weekly", "seedling").and_return(
               {
                 "minute" => 19,
                 "hour" => 19,
                 "weekday" => 6,
                 "OnCalendar" => "Sat *-*-* 19:19:00"
               }
             )
    end
  end
end
