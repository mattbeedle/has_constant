module HasConstant
  module Orm
    module ActiveModel
      extend ActiveSupport::Concern

      module ClassMethods
        def has_constant( name, values = lambda { I18n.t(name) }, options = {} )
          super(name, values, options)

          singular = (options[:accessor] || name.to_s.singularize).to_s

          # Add the getter method. This returns the string representation of
          # the stored value
          define_method(singular) do
            if read_attribute(singular)
              if values.is_a?(Array)
                self.class.send(name)[read_attribute(singular).to_i]
              elsif values.is_a?(Hash)
                self.class.send(name)[read_attribute(singular)]
              end
            end
          end

          define_method("#{singular}=") do |val|
            if values.is_a?(Array) && val.instance_of?(String)
              write_attribute singular.to_sym, self.class.send(name.to_s).index(val)
            elsif values.is_a?(Hash) && values.has_value?(val)
              write_attribute singular.to_sym, values.invert[val].to_s
            else
              write_attribute singular.to_sym, val
            end
          end

          class_eval do
            if respond_to?(:scope)
              scope :by_constant, lambda { |constant,value| { :conditions =>
                { constant.to_sym =>
                  eval("#{self.to_s}.#{constant.pluralize}.index(value)") } } }

              scope "#{singular}_is".to_sym, lambda { |*values| { :conditions =>
                { singular.to_sym => indexes_for(name, values) }
              } }

              scope "#{singular}_is_not".to_sym, lambda { |*values| {
                :conditions => ["#{singular} NOT IN (?)",
                                indexes_for(name, values)] } }
            else
              named_scope :by_constant, lambda { |constant,value| {
                :conditions =>
                { constant.to_sym =>
                  eval("#{self.to_s}.#{constant.pluralize}.index(value)") } } }

              named_scope "#{singular}_is".to_sym, lambda { |*values| {
                :conditions => { singular.to_sym => indexes_for(name, values) }
              } }

              named_scope "#{singular}_is_not".to_sym, lambda { |*values| {
                :conditions => ["#{singular} NOT IN (?)",
                                indexes_for(name, values)] } }
            end
          end
        end

      private
        def indexes_for( name, values )
          values.map { |v| self.send(name.to_sym).index(v) }
        end
      end
    end
  end
end
