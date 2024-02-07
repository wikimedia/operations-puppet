# SPDX-License-Identifier: Apache-2.0
require_relative '../../../../rake_modules/spec_helper'

describe 'network::constants', :type => :class do
    context "on production" do
        let(:facts) {{ :realm => 'production' }}
        it { should compile }
    end
    context "on labs" do
        let(:facts) {{ :realm => 'labs' }}
        it { should compile }
    end
    context "on cloud" do
        # realm => cloud is not yet in use, but this class should not be
        # blocking that anymore
        let(:facts) {{ :realm => 'cloud' }}
        it { should compile }
    end
end
