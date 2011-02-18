require 'helper'

setup_active_record

class User < ActiveRecord::Base
  include HasConstant

  has_constant :salutations, ['Mr', 'Mrs']
end

class ActiveRecordTest < Test::Unit::TestCase
  should 'save values as integers' do
    u = User.new(:salutation => 'Mr')
    u.save!
    assert_equal 'Mr', u.salutation
    assert_equal 0, u.attributes['salutation']
  end

  context 'scopes' do
    setup do
      @man = User.create!(:salutation => 'Mr')
      @woman = User.create!(:salutation => 'Mrs')
    end

    should 'provide by_constant scope' do
      assert_equal 1, User.by_constant('salutation', 'Mr').count
      assert_equal @man, User.by_constant('salutation', 'Mr').first
    end

    should 'provide singular_is scope' do
      assert_equal 1, User.salutation_is('Mr').count
      assert_equal @man, User.salutation_is('Mr').first
    end

    should 'provide singular_is_not scope' do
      assert_equal 1, User.salutation_is_not('Mr').count
      assert_equal @woman, User.salutation_is_not('Mr').first
    end
  end
end if defined?(ActiveRecord)
