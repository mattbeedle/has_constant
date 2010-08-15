module HasConstant
  module Orm
    module Mongoid
      def self.included( base )
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          validate :validate_has_constant_attributes
        end
      end

      module InstanceMethods
        def validate_has_constant_attributes
          @has_constant_errors.each do |key, value|
            self.errors.add key, value
          end if @has_constant_errors
        end
      end

      module ClassMethods
        def has_constant( name, values, options = {} )
          super(name, values, options)

          singular = (options[:accessor] || name.to_s.singularize).to_s

          # Add the getter method. This returns the string representation of the stored value
          define_method(singular) do
            eval("#{self.class}.#{name.to_s}[self.attributes[singular].to_i] if self.attributes[singular]")
          end

          define_method("#{singular}=") do |val|
            if val.instance_of?(String)
              if index = self.class.send(name.to_s).index(val)
                write_attribute singular.to_sym, index
              elsif !val.blank?
                values = values.call if values.respond_to?(:call)
                @has_constant_errors ||= {}
                @has_constant_errors.merge!(singular.to_sym => "must be one of #{values.join(', ')}")
              end
            else
              write_attribute singular.to_sym, val
            end
          end

          class_eval do
            named_scope :by_constant, lambda { |constant,value| { :where =>
              { constant.to_sym => eval("#{self.to_s}.#{constant.pluralize}.index(value)") } } }
            named_scope "#{singular}_is".to_sym, lambda { |*values| { :where =>
              { singular.to_sym => { '$in' =>  values.map { |v| self.send(name.to_sym).index(v) } } } } }
            named_scope "#{singular}_is_not".to_sym, lambda { |*values| { :where =>
              { singular.to_sym => { '$nin' => values.map { |v| self.send(name.to_sym).index(v) } } } } }
          end
        end
      end
    end
  end
end
