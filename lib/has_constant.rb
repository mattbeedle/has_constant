require 'active_support'
require 'has_constant/orm/mongoid'
require 'has_constant/orm/active_model'
require 'active_support/inflector'

module HasConstant
  extend ActiveSupport::Concern

  included do
    if defined?(Mongoid) && ancestors.include?(Mongoid::Document)
      send(:include, HasConstant::Orm::Mongoid)
    elsif defined?(ActiveModel) && !ancestors.map(&:to_s).grep(/^ActiveModel/).blank?
      send(:include, HasConstant::Orm::ActiveModel)
    end
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
    def has_constant(name, values = lambda { I18n.t(name) }, options = {})
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
          if values.index(val)
            instance_variable_set("@#{singular}", values.index(val))
          else
            raise ArgumentError,
              "value for #{singular} must be in #{self.class.send(name.to_s).join(', ')}"
          end
        else
          instance_variable_set("@#{singular}", val)
        end
      end

      define_method("#{singular}_is?") do |value|
        send(singular) == value.to_s
      end

      define_method("#{singular}_is_not?") do |value|
        !send("#{singular}_is?", value)
      end

      define_method("#{singular}_in?") do |value_list|
        value_list.include? send(singular)
      end

      define_method("#{singular}_not_in?") do |value_list|
        !send("#{singular}_in?", value_list)
      end
    end
  end
end
