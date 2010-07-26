require 'has_constant/orm/mongoid'
require 'has_constant/orm/active_record'
require 'active_support/inflector'
module HasConstant

  def self.included(base)
    base.extend(ClassMethods)
  end

  # HasConstant takes a Proc containing an array of possible values for a field name
  # The field name is inferred as the singular of the has constant name. For example
  # has_constant :titles
  # would use the database column "title"
  #
  # USAGE:
  #
  # class User < ActiveRecord::Base
  #   include HasConstant
  #   has_constant :titles, lambda { %w(Mr Mrs) }
  # end
  #
  # User.titles #=> ['Mr', 'Ms']
  #
  # @user = User.new(:title => 'Mr')
  # @user.title #=> 'Mr'
  # @user.attributes['title'] #=> 0
  #
  # @user.title_is?('Mr') #=> true
  # @user.title_is?('Ms') #=> false
  #
  # User.by_constant('title', 'Mr') #=> [@user]
  #
  module ClassMethods
    def has_constant(name, values, options = {})

      singular = (options[:accessor] || name.to_s.singularize).to_s

      (class << self; self; end).instance_eval do
        define_method(name.to_s, values) if values.respond_to?(:call)
        define_method(name.to_s, lambda { values }) unless values.respond_to?(:call)
      end

      define_method(singular) do
        values[instance_variable_get("@#{singular}")]
      end

      # Add the setter method. This takes the string representation and converts it to an integer to store in the DB
      define_method("#{singular}=") do |val|
        if val.instance_of?(String)
          instance_variable_set("@#{singular}", values.index(val))
        else
          instance_variable_set("@#{singular}", val)
        end
      end

      define_method("#{singular}_is?") do |value|
        eval("#{singular} == '#{value.to_s}'")
      end
    end
  end
end
