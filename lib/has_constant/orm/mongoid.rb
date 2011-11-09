module HasConstant
  module Orm
    module Mongoid
      extend ActiveSupport::Concern

      included do
        class_eval do
          validate :validate_has_constant_attributes
        end
      end

      def validate_has_constant_attributes
        @has_constant_errors.each do |key, value|
          self.errors.add key, value
        end if @has_constant_errors
      end

      module ClassMethods
        def has_constant( name, values = lambda { I18n.t(name) }, options = {} )
          super(name, values, options)

          singular = (options[:accessor] || name.to_s.singularize).to_s
          plural = (options[:accessor] || name.to_s)

          class_eval do
            unless fields.map(&:first).include?(singular.to_s)
              if options[:as] == :array
                field plural.to_sym, { :type => Array, :default => [] }.
                  merge(options)
              else
                if values.is_a?(Hash) || values.respond_to?(:call) &&
                  values.call.is_a?(Hash)
                  type = String
                else
                  type = Integer
                end
                field singular.to_sym, { :type => type }.merge(options)
              end
            end

            index singular.to_sym, :background => true if options[:index]

            unless respond_to?(:by_constant)
              named_scope :by_constant, lambda { |constant, value|
                if self.send(constant.pluralize).respond_to?(:key)
                  value_for_query = self.send(constant.pluralize).key(value)
                  value_for_query ||= I18n.with_locale(:en) do
                    self.send(constant.pluralize).key(value)
                  end
                else
                  value_for_query = self.send(constant.pluralize).index(value)
                  value_for_query ||= I18n.with_locale(:en) do
                    send(contant.pluralize).index(value)
                  end
                end
                where(constant.to_sym => value_for_query)
              }
            end
          end

          # Define the setter method here
          if options[:as] == :array
            define_method("#{plural}=") do |value_set|
              indexes = (value_set.blank? ? [] : value_set).map do |value|
                if self.class.send(plural).respond_to?(:key)
                  self.class.send(plural).key(value)
                else
                  self.class.send(plural).index(value)
                end
              end
              write_attribute plural, indexes
            end
          end

          define_method("#{singular}=") do |val|
            if val.instance_of?(String)
              if self.class.send(name).respond_to?(:key)
                index = self.class.send(name.to_s).key(val).to_s
              elsif self.class.send(name).respond_to?(:index)
                index = self.class.send(name.to_s).index(val)
                index = index.to_s if self.class.send(name.to_s).is_a?(Hash)
              end
              if index
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

          # Add the getter method. This returns the string representation of the stored value
          if options[:as] == :array
            define_method(plural) do
              attributes[plural].map { |val| self.class.send(plural)[val] }
            end
          end

          define_method(singular) do
            if attributes[singular]
              res = self.class.send(name.to_s)[attributes[singular].to_i] rescue nil
              res ||= self.class.send(name.to_s)[attributes[singular]]
              res ||= self.class.send(name.to_s)[attributes[singular].to_sym]
            end
          end

          (class << self; self; end).instance_eval do
            if options[:as] == :array
              define_method "#{plural}_include".to_sym do |value|
                if value.is_a?(String)
                  if values.respond_to?(:key)
                    where(plural.to_sym => values.key(value))
                  else
                    where(plural.to_sym => values.index(value))
                  end
                else
                  if values.respond_to?(:key)
                    where(plural.to_sym => value.map { |v| send(plural).key(v) })
                  else
                    where(plural.to_sym => value.map { |v| send(plural).index(v) })
                  end
                end
              end
            else
              define_method "#{singular}_is".to_sym do |values|
                values = values.lines.to_a if values.respond_to?(:lines)
                where(singular.to_sym.in => values.map do |v|
                  if send(name).respond_to?(:key)
                    send(name).key(v) || I18n.with_locale(:en) { send(name).key(v) }
                  else
                    send(name).index(v) || I18n.with_locale(:en) { send(name).index(v) }
                  end
                end)
              end

              define_method "#{singular}_is_not".to_sym do |values|
                values = values.lines.to_a if values.respond_to?(:lines)
                if send(plural).respond_to?(:key)
                  values_for_query = values.map { |v| send(plural).key(v) }.compact
                  values_for_query = values.map do |v|
                    I18n.with_locale(:en) { send(plural).key(v) }
                  end.compact if values_for_query.blank?
                else
                  values_for_query = values.map { |v| send(plural).index(v) }.compact
                  values_for_query = values.map do |v|
                    I18n.with_locale(:en) { send(plural).index(v) }
                  end.compact if values_for_query.blank?
                end
                where(singular.to_sym.nin => values_for_query)
              end
            end
          end
        end
      end
    end
  end
end
