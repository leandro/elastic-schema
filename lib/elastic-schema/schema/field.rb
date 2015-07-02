module ElasticSchema::Schema

  class Field
    attr_reader :name, :type, :children, :attributes, :parent

    def initialize(field_name, type = 'object', attrs)
      @name       = field_name.to_s
      @type       = type.to_s
      @parent     = attrs.delete(:parent)
      @attributes = attrs.inject({}) { |_attrs, (attr, value)| _attrs.update(attr.to_s => value) }
      @children   = FieldsSet.new(self)
    end

    def find(field_name)
      @children.find(field_name)
    end

    def full_name
      "#{parent.full_name}.#{name}"
    end

    def to_hash
      {
        name => {
          'type' => type
        }.merge(attributes)
      }.merge(children.to_hash)
    end
  end

end
