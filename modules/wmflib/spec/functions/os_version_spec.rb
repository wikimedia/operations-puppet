require 'spec_helper'

describe 'os_version' do

    it { should_not be_nil, 'expected function to be defined' }

    context 'when invoked with no arguments' do
        it 'raises an error' do
            should run.with_params().and_raise_error(ArgumentError)
        end
    end

    context 'intentionally failing' do
        let(:facts) do
            {
                :lsbdistrelease => '12.04',
                :lsbdistid => 'Ubuntu',
            }
        end

        # Used to generate the following non obvious error which seems to be an
        # incompatibility between rspec-puppet and rspec :(
        #
        #  1) os_version intentionally failing fails for demo
        #     Failure/Error: should run.with_params('ubuntu == precise').and_return(false)
        #     ArgumentError:
        #       wrong number of arguments (0 for 1)
        it 'fails for demo' do
            should run.with_params('ubuntu == precise').and_return(false)
        end
    end

    context 'when running on Ubuntu Precise 12.04' do
        let(:facts) do
            {
                :lsbdistrelease => '12.04',
                :lsbdistid => 'Ubuntu',
            }
        end

        it 'matches properly' do
            should run.with_params('ubuntu == precise').and_return(true)
            should run.with_params('ubuntu == trusty').and_return(false)
            should run.with_params('ubuntu >= precise').and_return(true)
            should run.with_params('ubuntu > precise').and_return(false)
            should run.with_params('ubuntu >= trusty').and_return(false)
            should run.with_params('ubuntu > trusty').and_return(false)
        end
    end

    context 'when running on Ubuntu Trusty 14.04' do
        let(:facts) do
            {
                :lsbdistrelease => '14.04',
                :lsbdistid => 'Ubuntu',
            }
        end

        it 'matches properly' do
            should run.with_params('ubuntu == precise').and_return(false)
            should run.with_params('ubuntu == trusty').and_return(true)
            should run.with_params('ubuntu >= precise').and_return(true)
            should run.with_params('ubuntu > precise').and_return(true)
            should run.with_params('ubuntu >= trusty').and_return(true)
            should run.with_params('ubuntu > trusty').and_return(false)
        end
    end
end
