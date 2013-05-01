require_relative 'spec_helper'

describe "ApiService" do
    
    it "should respond to GET" do
        get '/'
        last_response.status.should == 200
        last_response.body.should match(/Welcome to the API service/)
    end

    it "should have caching" do
        get '/testcache'
        last_response.status.should == 200
    end


    describe "Should authenticate correctly" do

    	it "should return 500 if request is bogus" do
            request_header = {}
            request_header['HTTP_AUTHORIZATION'] = "PassAuthToken"
    		post '/v1/service/authenticate', {}, request_header 
    		last_response.status.should == 500
        end

        it "should return 400 if username missing" do
            authorize '', 'boy'
            post '/v1/service/authenticate'
    		last_response.status.should == 400
        end

        it "should return 401 if username not authorized" do
            authorize 'bad', 'boy'
    		post '/v1/service/authenticate'
    		last_response.status.should == 401
        end

        it "should return 400 if authentication goes correctly - user assigned more then one business unit" do
            authorize 'hsimpson', 'h0m3rs1mps0n'
    		post '/v1/service/authenticate'
    		last_response.status.should == 400
            last_response.body.should == '{"error":"User is assigned to more then one business entity"}'
        end

        it "should return 200 if authentication goes correctly" do
            authorize 'dev@carecloud.com', 'welcome'
            post '/v1/service/authenticate'
            last_response.status.should == 200
        end

    end

	describe "Should get patient data correctly" do

		it "should return 400 if request is not valid" do
    		get '/v1/patients/222'
    		last_response.status.should == 400
    end

    it "should return 400 if request is not valid" do
    		get '/v1/patients/patient-2222222222222222222222222222222222222222222222222222222222222222222222222222222222'
    		last_response.status.should == 400
    end

    it "should return 500 if request is no auth token" do
    		get '/v1/patients/patient-2222'
    		last_response.status.should == 500
    end

    it "should return 500 if request is not authorized" do
    		get '/v1/patients/patient-2222?authentication=3333333'
    		last_response.status.should == 403
    		last_response.body.should == '{"error":{"error_code":"0037","message":"Authorization Failed","error_type":"Generic","details":null}}'
    end

        # setup accurate request of patient data
    it "should return 200 if request is valid" do
        	authorize 'dev@carecloud.com', 'welcome'
    		post '/v1/service/authenticate'
    		var1 = last_response.body
    		url = '/v1/patients/patient-1234?authentication='
    		url << var1
    		get url
    		puts last_response.body
    		last_response.status.should == 200
    end

	end

    describe "Should save patient data" do

        the_patient_id_to_use = ''

        it "should return 403 if request is not authorized" do
            var1 = '{"todo":"this"}'
            post '/v1/patients/create?authentication=3333333', var1
            last_response.status.should == 403
            last_response.body.should == '{"error":{"error_code":"0037","message":"Authorization Failed","error_type":"Generic","details":null}}'
        end

        it "should return 400 if request is in valid" do
          authorize 'dev@carecloud.com', 'welcome'
            post '/v1/service/authenticate'
            var1 = last_response.body
            url = '/v1/patients/create?authentication='
            url << var1

            var1 = '{"todo":"this"}'
            put url, var1
            puts last_response.body
            last_response.status.should == 400
        end

        it "should return 200 if request is in valid" do
          authorize 'dev@carecloud.com', 'welcome'
            post '/v1/service/authenticate'
            var1 = last_response.body
            url = '/v1/patients/create?authentication='
            url << var1

            var1 = '{
        "patient": {
            "first_name": "bob",
            "last_name": "smith",
            "middle_initial": "E",
            "email": "no@email.com",
            "prefix": "mr",
            "suffix": "jr",
            "ssn": "123-45-6789",
            "gender_id": "1",
            "date_of_birth": "2000-03-12"
        },
        "addresses": {
            "line1": "123 fake st",
            "line2": "apt3",
            "city": "newton",
            "state_code": "ma",
            "zip_code": "07488",
            "county_name": "suffolk",
            "latitude": "",
            "longitude": "",
            "country_id": "225"
        },
        "phones": [
            {
                "phone_number": "5552221212",
                "phone_type_id": "3",
                "extension": "3433"
            },
            {
                "phone_number": "3332221212",
                "phone_type_id": "2",
                "extension": "5566"
            }
        ]
    }'


            post url, var1
            puts last_response.body
            the_patient_id_to_use = last_response.body
            last_response.status.should == 201
        end

        it "should update the patient" do
          authorize 'dev@carecloud.com', 'welcome'
            post '/v1/service/authenticate'
            var1 = last_response.body
            url = '/v1/patients/patient-' 
            url << the_patient_id_to_use 
            url << '?authentication='
            url << var1

            var1 = '{
        "patient": {
            "first_name": "Roger",
            "last_name": "smith",
            "middle_initial": "E",
            "email": "no@email.com",
            "prefix": "mr",
            "suffix": "jr",
            "ssn": "123-45-6789",
            "gender_id": "1",
            "date_of_birth": "2000-03-12"
        },
        "addresses": {
            "line1": "123 fake st",
            "line2": "apt3",
            "city": "newton",
            "state_code": "ma",
            "zip_code": "07488",
            "county_name": "suffolk",
            "latitude": "",
            "longitude": "",
            "country_id": "225"
        },
        "phones": [
            {
                "phone_number": "5552221212",
                "phone_type_id": "3",
                "extension": "3433"
            },
            {
                "phone_number": "3332221212",
                "phone_type_id": "2",
                "extension": "5566"
            }
        ]
    }'
            put url, var1
            puts last_response.body
            ## todo check response for ROGER
            last_response.status.should == 200
        end

        it "should return delete the patient" do
          authorize 'dev@carecloud.com', 'welcome'
            post '/v1/service/authenticate'
            var1 = last_response.body
            url = '/v1/patients/patient-' 
            url << the_patient_id_to_use
            url << '?authentication='
            url << var1

            delete url, var1
            puts last_response.body
            last_response.status.should == 200
        end
     end


    describe "Should save appointment data" do

      the_appt_id_to_use = ''

      it "should return 200 if locations request is valid" do
          authorize 'dev@carecloud.com', 'welcome'
          post '/v1/service/authenticate'
          var1 = last_response.body
          url = '/v1/appointment/locations?authentication='
          url << var1
          get url
          puts last_response.body
          last_response.status.should == 200
      end
     
      it "should return 200 if providers request is valid" do
          authorize 'dev@carecloud.com', 'welcome'
          post '/v1/service/authenticate'
          var1 = last_response.body
          url = '/v1/appointment/providers?authentication='
          url << var1
          get url
          puts last_response.body
          last_response.status.should == 200
      end

       it "should return 200 if resources request is valid" do
          authorize 'dev@carecloud.com', 'welcome'
          post '/v1/service/authenticate'
          var1 = last_response.body
          url = '/v1/appointment/resources?authentication='
          url << var1
          get url
          puts last_response.body
          last_response.status.should == 200
      end

      it "should return 200 if appt by date request is valid" do
          authorize 'dev@carecloud.com', 'welcome'
          post '/v1/service/authenticate'
          var1 = last_response.body
          url = '/v1/appointment/20130423/provider-2?authentication='
          url << var1
          get url
          puts last_response.body
          last_response.status.should == 200
      end

        it "should return 400 if request is in invalid provider" do
          authorize 'dev@carecloud.com', 'welcome'
            post '/v1/service/authenticate'
            var1 = last_response.body
            url = '/v1/appointment/create?authentication='
            url << var1

            var1 = '{
        "appointment": {
            "start_time": "2013-04-24 10:20",
            "end_time": "2013-04-24 11:00",
            "location_id": 2,
            "nature_of_visit_id": 2,
            "provider_id": 222222222222222,
            "patients": [
                {
                    "id": 1819622,
                    "comments": "patienthasheadache"
                }]
        }
    }'


            post url, var1
            puts last_response.body
            last_response.status.should == 400
        end

        it "should return 200 if request is in valid" do
          authorize 'dev@carecloud.com', 'welcome'
            post '/v1/service/authenticate'
            var1 = last_response.body
            url = '/v1/appointment/create?authentication='
            url << var1

            var1 = '{
        "appointment": {
            "start_time": "2014-04-24 10:35",
            "end_time": "2014-04-24 11:00",
            "location_id": 2,
            "nature_of_visit_id": 2,
            "provider_id": 2,
            "patients": [
                {
                    "id": "85093a6d-8c43-47ec-ab9d-82a30cc1db25",
                    "comments": "patienthasheadache"
                }]
        }
    }'


            post url, var1
            puts last_response.body
            the_appt_id_to_use = last_response.body
            last_response.status.should == 201
        end

        it "should return 400 bad provider to delete appointment " do
          authorize 'dev@carecloud.com', 'welcome'
            post '/v1/service/authenticate'
            var1 = last_response.body
            url = '/v1/appointment/22222222222222222/' 
            url << the_appt_id_to_use
            url << '?authentication='
            url << var1

            delete url, var1
            puts last_response.body
            last_response.status.should == 400
        end

        it "should return 200 to delete appointment " do
          authorize 'dev@carecloud.com', 'welcome'
            post '/v1/service/authenticate'
            var1 = last_response.body
            url = '/v1/appointment/2/' 
            url << the_appt_id_to_use
            url << '?authentication='
            url << var1

            delete url, var1
            puts last_response.body
            last_response.status.should == 200
        end

    end

end