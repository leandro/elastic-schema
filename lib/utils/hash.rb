class Hash
  def deep_slice(*keys)
    keys.inject({}) do |new_hash, key|
      if key.is_a?(Array)
        next new_hash unless self.has_key?(key.first)
        inner_hash = new_hash.include?(key.first) ? new_hash[key.first] : {}
        inner_hash.update(self[key.first].deep_slice(*key[1..-1]))
        new_hash.update(key.first => inner_hash)
      else
        next new_hash unless self.has_key?(key)
        new_hash.update(key => self[key])
      end
    end
  end
end
