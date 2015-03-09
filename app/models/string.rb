class String

  def is_guid?
    match = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.match to_s
    match ? true : false
  end

  def is_integer?
    self.to_i.to_s == self
  end

end
