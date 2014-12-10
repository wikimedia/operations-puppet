require 'spec_helper'

describe 'os_version' do

    describe 'when invoked with no arguments' do
        it "raises an error" do
            should run.with_params().and_raise_error(ArgumentError)
        end
    end

    describe 'when running on Ubuntu Precise 12.04' do
        let(:facts) do
            {
                :lsbdistrelease => '12.04',
                :lsbdistid => 'Ubuntu',
            }
        end

        it "matches properly" do
            should run.with_params('ubuntu == precise').and_return(true)
            should run.with_params('ubuntu == trusty').and_return(false)
        end
    end
end
