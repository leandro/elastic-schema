class Hash
  def deep_slice(*keys)
    keys.inject({}) do |new_hash, key|
      if key.is_a?(Array)
        inner_hash = new_hash.include?(key.first) ? new_hash[key.first] : {}
        inner_keys = key[1..-1]
        inner_keys = inner_keys.first if inner_keys.size == 1
        next new_hash unless self[key.first].is_a?(Hash)
        inner_hash.deep_merge!(self[key.first].deep_slice(inner_keys))
        new_hash.update(key.first => inner_hash)
      else
        next new_hash unless self.has_key?(key)
        new_hash.update(key => self[key])
      end
    end
  end

  def deep_transform_values(&block)
    return enum_for(:deep_transform_values) unless block_given?

    inject(self.class.new) do |memo, (key, value)|
      memo[key] = value.is_a?(Hash) ? value.deep_transform_values(&block) : yield(value)
    end
  end

  def deep_transform_values!(&block)
    return enum_for(:deep_transform_values) unless block_given?

    inject(self) do |memo, (key, value)|
      memo[key] = value.is_a?(Hash) ? value.deep_transform_values(&block) : yield(value)
    end
  end
end
