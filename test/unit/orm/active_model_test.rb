require 'helper'
require 'mocha'

setup_active_record

class User < ActiveRecord::Base
  include HasConstant
end

class Thing < ActiveRecord::Base
  include HasConstant
end

class ActiveModelTest < Test::Unit::TestCase
  context 'Instance' do
    context 'using a hash' do
      setup do
        Thing.has_constant :salutations, { :first => 'Mr', :second => 'Mrs' }
        @u = Thing.new :salutation => 'Mrs'
      end

      should 'store the hash key' do
        assert_equal 'second', @u.attributes['salutation']
      end

      should 'return the correct value' do
        assert_equal 'Mrs', @u.salutation
      end
    end

    should 'save values as integers' do
      User.has_constant :salutations, %w(Mr Mrs)
      u = User.new(:salutation => 'Mr')
      u.save!
      assert_equal 'Mr', u.salutation
      assert_equal 0, u.attributes['salutation']
    end

    should 'default values to translated values list' do
      I18n.stubs(:t).returns(['a', 'b'])
      User.has_constant :salutations
      assert_equal ['a', 'b'], User.salutations
    end

    context 'accessor' do
      setup do
        User.has_constant :titles, ['Mr', 'Mrs'], :accessor => :salutation
        @user = User.new(:salutation => 'Mr')
      end

      should 'work store the values in the correct field ' do
        @user.save!
        assert_equal 0, @user.attributes['salutation']
      end

      should 'use the accessor to get values' do
        assert_equal 'Mr', @user.salutation
      end

      should 'use constant name for values list' do
        assert_equal %w(Mr Mrs), User.titles
      end
    end
  end

  context 'scopes' do
    setup do
      User.has_constant :salutations, %w(Mr Mrs)
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
