module ElasticSchema::Schema

  class Field
    attr_accessor :parent
    attr_reader :name, :type, :children, :attributes

    def initialize(field_name, field_type = nil, attrs, &block)
      @name       = field_name.to_s
      @parent     = attrs.delete(:parent)
      @children   = FieldsSet.new(self)
      @attributes = attrs.inject({}) { |_attrs, (attr, value)| _attrs.update(attr.to_s => value.to_s) }
      field_type  = (block_given? ? 'object' : 'string') if field_type.nil?
      @type       = field_type

      filter_attributes_for_special_cases
    end

    def find(field_name)
      children.find(field_name)
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
