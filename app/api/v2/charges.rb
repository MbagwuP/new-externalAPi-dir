class ApiService < Sinatra::Base

  post '/v2/charges' do
    input_json = get_request_JSON
=begin
    input_json = {
      "charge"                          => {
        "patient_id"                    => "2965fb69-2d2d-459c-87d8-ba6778254122",
        "amount"                        => 250.0,
        "insurance_profile"             => "default",
        "post_immediately"              => true,        # if false, Charge is saved but not posted
        "provider_id"                   => "9",
        # "attending_provider_id"       => null,
        # "referring_physician_id"      => null,
        # "supervising_provider_id"     => null,
        # "authorization_id"            => null,       # ???
        # "clinical_case_id"            => null,
        "location_id"                   => "945",
        "start_time"                    => "2015-06-03T14:00:00-04:00",
        "end_time"                      => "2015-06-03T14:30:00-04:00",
        # "units"                       => 1,
        # "ndc_number"                  => null,
        # "ndc_quantity"                => null,
        # "ndc_uom"                     => null,
        # "onset_date"                  => null,
        # "accident_date"               => null,
        # "accident_state"              => null,
        # "treatment_date"              => null,
        "procedure_code"                => "99253",
        # "procedure_short_description" => null,
        # "diagnosis_codes"             => ["285.9", "303.9"],
        "diagnosis_codes"               => ["285.9"],
        "modifier_codes"                => ["CF"],
        "icd_indicator"                 => 9
      }
    }
=end

    input_json = input_json['charge']

    forwarded_json = {}

    ['amount', 'location_id', 'icd_indicator',
     'date_of_service_from', 'date_of_service_to',
     'provider_id', 'procedure_code', 'patient_id'].each do |forwarded_field|
        forwarded_json[forwarded_field] = input_json[forwarded_field]
    end

    input_json['diagnosis_codes'].each_with_index do |code, index|
      forwarded_json["diagnosis#{index + 1}_code"] = code
    end

    # forwarded_json['date_of_service_from'] = input_json['start_time']
    # forwarded_json['date_of_service_to']   = input_json['end_time']
    forwarded_json['is_outbound']          = false
    # forwarded_json['import_status_id']     = 1 # Ready Status ImportStatus::READY
    # forwarded_json['import_at']            = Time.now.iso8601 # put this in WS
    forwarded_json['interface_id']         = 2087

    urlcharge = webservices_uri "charge_stagings/create.json",
                                {token: escaped_oauth_token, business_entity_id: current_business_entity}.compact

    resp = rescue_service_call 'Charge Creation' do
      response = RestClient.post(urlcharge, {charge_staging: forwarded_json}.to_json,
        {:content_type => :json, :api_key => APP_API_KEY})
    end
  end

end
