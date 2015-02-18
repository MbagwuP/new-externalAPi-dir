class Hash
  # Returns a hash with non +nil+ values.
  #
  #   hash = { a: true, b: false, c: nil}
  #   hash.compact # => { a: true, b: false}
  #   hash # => { a: true, b: false, c: nil}
  #   { c: nil }.compact # => {}
  def compact
    self.select { |_, value| !value.nil? }
  end

  # Replaces current hash with non +nil+ values.
  #
  #   hash = { a: true, b: false, c: nil}
  #   hash.compact! # => { a: true, b: false}
  #   hash # => { a: true, b: false}
  def compact!
    self.reject! { |_, value| value.nil? }
  end

  def rename_key old_key, new_key
    # if self[old_key]
      self[new_key] = self[old_key]
      self.delete(old_key)
    # end
  end
end
