class Hash
  def deep_slice(*keys)
    keys.inject({}) do |new_hash, key|
      if key.is_a?(Array)
        inner_hash = new_hash.include?(key.first) ? new_hash[key.first] : {}
        inner_keys = key[1..-1]
        inner_keys = inner_keys.first if inner_keys.size == 1
        inner_hash.update(self[key.first].deep_slice(inner_keys))
        new_hash.update(key.first => inner_hash)
      else
        next new_hash unless self.has_key?(key)
        new_hash.update(key => self[key])
      end
    end
  end
end
