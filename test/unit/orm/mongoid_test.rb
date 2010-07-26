require 'helper'

setup_mongoid

class MongoUser
  include Mongoid::Document
  include HasConstant
  include HasConstant::Orm::Mongoid

  field :salutation, :type => Integer

  has_constant :salutations, ['Mr', 'Mrs']
end if defined?(Mongoid)

class MongoidTest < Test::Unit::TestCase
  should 'save values as integers' do
    m = MongoUser.new(:salutation => 'Mr')
    m.save!
    assert_equal 'Mr', m.salutation
    assert_equal 0, m.attributes['salutation']
  end

  context 'scopes' do
    setup do
      @man = MongoUser.create!(:salutation => 'Mr')
      @woman = MongoUser.create!(:salutation => 'Mrs')
    end

    should 'provide by_constant scope' do
      assert_equal 1, MongoUser.by_constant('salutation', 'Mr').count
      assert_equal @man, MongoUser.by_constant('salutation', 'Mr').first
    end

    should 'provide singular_is scope' do
      assert_equal 1, MongoUser.salutation_is('Mr').count
      assert_equal @man, MongoUser.salutation_is('Mr').first
    end

    should 'provide singular_is_not scope' do
      assert_equal 1, MongoUser.salutation_is_not('Mr').count
      assert_equal @woman, MongoUser.salutation_is_not('Mr').first
    end
  end
end if defined?(Mongoid)
