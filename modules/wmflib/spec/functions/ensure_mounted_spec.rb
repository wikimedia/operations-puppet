require 'spec_helper'

describe "the ensure_mounted function" do
  it "should exist" do
    Puppet::Parser::Functions.function("ensure_mounted").should == "function_ensure_mounted"
  end

  it "should raise a ParseError if there are less than 1 arguments" do
    ->{ scope.function_ensure_mounted([]) }.should(raise_error(ArgumentError))
  end

  it "should raise a ParseError if there are more than 1 arguments" do
    ->{ scope.function_ensure_mounted(['a', 'b']) }.should(raise_error(ArgumentError))
  end

  it "should return 'mounted' for param 'present'" do
    result = scope.function_ensure_mounted(['present'])
    result.should(eq('mounted'))
  end

  it "should return 'mounted' for param 'true'" do
    result = scope.function_ensure_mounted([true])
    result.should(eq('mounted'))
  end

  it "should return 'absent' for param 'absent'" do
    result = scope.function_ensure_mounted(['absent'])
    result.should(eq('absent'))
  end

  it "should return 'false' for param 'false'" do
    result = scope.function_ensure_mounted([false])
    result.should(eq(false))
  end

end
