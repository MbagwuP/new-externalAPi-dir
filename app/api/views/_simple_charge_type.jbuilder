if simple_charge_type['status'] == 'A'
  json.id simple_charge_type['id']
  json.name simple_charge_type['name']
  json.status simple_charge_type['status']
  json.default_units simple_charge_type['default_units']
  json.amount simple_charge_type['amount']
  json.location_required simple_charge_type['location_required']
  json.provider_required simple_charge_type['provider_required']
end
#
# {"amount"=>"0.0",
#     "business_entity_id"=>64,
#     "code"=>"OTHER",
#     "created_at"=>"2011-01-05T01:14:01-05:00",
#     "created_by"=>20,
#     "default_units"=>1,
#     "description"=>"OTHER",
#     "id"=>378,
#     "location_required"=>false,
#     "name"=>"OTHER",
#     "provider_required"=>false,
#     "sort_code"=>nil,
#     "status"=>"I",
#     "updated_at"=>"2013-08-18T13:11:18-04:00",
#     "updated_by"=>15131}},
