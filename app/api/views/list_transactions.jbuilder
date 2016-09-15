json.array! @resp do |txn|

  json.id txn['id']
  json.amount txn['amount']
  json.balance txn['balance']
  json.unapplied_credit txn['unapplied_credit']
  json.posting_date txn['posting_date']
  json.transaction_type txn['transaction_type_name'].underscore.gsub(' ', '_')
  json.transaction_status txn['transaction_status_name'].underscore.gsub(' ', '_')
  json.location_id txn['location_id']
  json.provider_id txn['provider_id']
  json.attending_provider_id txn['attending_provider_id']
  json.units txn['units']
  json.description txn['description']

end
