require 'spec_helper'

describe 'network::constants', :type => :class do
    context "on production" do
        let(:facts) {{ :realm => 'production' }}
        it { should compile }
    end
    context "on labs" do
        let(:facts) {{ :realm => 'labs' }}
        it { should compile }
    end
end
