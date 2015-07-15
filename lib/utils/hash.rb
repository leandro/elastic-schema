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

  def deep_merge(other_hash, &block)
    dup.deep_merge!(other_hash, &block)
  end

  # Same as +deep_merge+, but modifies +self+.
  def deep_merge!(other_hash, &block)
    other_hash.each_pair do |current_key, other_value|
      this_value = self[current_key]

      self[current_key] = if this_value.is_a?(Hash) && other_value.is_a?(Hash)
        this_value.deep_merge(other_value, &block)
      else
        if block_given? && key?(current_key)
          block.call(current_key, this_value, other_value)
        else
          other_value
        end
      end
    end

    self
  end
end
