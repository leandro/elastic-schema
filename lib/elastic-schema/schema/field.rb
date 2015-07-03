module ElasticSchema::Schema

  class Field
    attr_reader :name, :type, :children, :attributes, :parent

    def initialize(field_name, type = 'object', attrs)
      @name       = field_name.to_s
      @type       = type.to_s
      @parent     = attrs.delete(:parent)
      @children   = FieldsSet.new(self)
      @attributes = attrs.inject({}) do |_attrs, (attr, value)|
                      value = value.to_s if value.is_a?(Symbol)
                      _attrs.update(attr.to_s => value)
                    end
      filter_attributes_for_special_cases
    end

    def find(field_name)
      @children.find(field_name)
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
      end
    end
  end

end
