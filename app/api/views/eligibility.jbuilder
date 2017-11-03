json.eligibility_request do
  json.id @eligibility_request['eligibility_request']['id']
  json.co_insurance @eligibility_request['eligibility_request']['co_insurance']
  json.co_payment @eligibility_request['eligibility_request']['co_payment']
  json.comments @eligibility_request['eligibility_request']['comments']
  json.deductible @eligibility_request['eligibility_request']['deductible']
  json.outstanding_deductible @eligibility_request['eligibility_request']['outstanding_deductible']
  json.date_of_service @eligibility_request['eligibility_request']['primary_insured_date_period']
end