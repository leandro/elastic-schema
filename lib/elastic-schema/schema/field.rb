module ElasticSchema::Schema

  class Field
    attr_accessor :parent
    attr_reader :name, :type, :children, :attributes

    def initialize(field_name, field_type = nil, attrs, &block)
      @name       = field_name.to_s
      @parent     = attrs.delete(:parent)
      @children   = FieldsSet.new(self)
      @attributes = attrs.deep_stringify_keys.deep_transform_values { |v| v.to_s }
      field_type  = (block_given? ? 'object' : 'string') if field_type.nil?
      @type       = field_type.to_s

      filter_attributes_for_special_cases
      instance_eval(&block) if block_given?
    end

    def field(field_name, field_type = nil, opts = {}, &block)
      children << Field.new(field_name, field_type, opts, &block)
    end

    def full_name
      "#{parent.full_name}.#{name}"
    end

    def to_hash
      attrs = type == 'object' ? {} : { 'type' => type }
      { name => attrs.merge(attributes).merge(children.to_hash) }
    end

    private

    def filter_attributes_for_special_cases
      case type
      when 'date'
        attributes.update('format' => 'dateOptionalTime') if type == 'date'
        attributes.delete('index')
      when *%w(integer long float double boolean null)
        attributes.delete('index')
        attributes.delete('analyzer')
      end
    end
  end

end
