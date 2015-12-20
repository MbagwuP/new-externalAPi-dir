# require_relative 'spec_helper'
#
# INTERFACE_USER = 'interface2@interface.com'
# INTERFACE_PASS = 'Welcome1['
#
# describe "ApiService" do
#
#   it "should respond to GET" do
#     get '/'
#     last_response.status.should == 200
#     last_response.body.should match(/Welcome the home page!/)
#   end
#
#   # it "should have caching" do
#   #   get '/testcache'
#   #   last_response.status.should == 200
#   # end
#
#   describe "Should authenticate correctly" do
#
#     it "should return 400 if request is bogus" do
#       request_header = {}
#       request_header['HTTP_AUTHORIZATION'] = "Basic PassAuthToken"
#       post '/v1/service/authenticate', {}, request_header
#       last_response.status.should == 400
#     end
#
#     it "should return 400 if username missing" do
#       authorize '', 'boy'
#       post '/v1/service/authenticate'
#       last_response.status.should == 400
#     end
#
#     it "should return 401 if username not authorized" do
#       authorize 'bad', 'boy'
#       post '/v1/service/authenticate'
#       last_response.status.should == 401
#     end
#
#     it "should return 400 if authentication goes correctly - user assigned more then one business unit" do
#       authorize 'jyeung@carecloud.com', 'welcome'
#       post '/v1/service/authenticate'
#       last_response.status.should == 400
#       last_response.body.should == '{"error":"User is assigned to more then one business entity"}'
#     end
#
#     it "should return 200 if authentication goes correctly" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       last_response.status.should == 200
#     end
#
#     it "should return 200 if logout goes correctly" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/service/logout?authentication='
#       url << var1
#       post url
#       last_response.status.should == 200
#     end
#
#
#     it "should return 500 if appointment id is not valid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v2/appointment/listbyid/f6b89311-1213232-42b6-bd70-aeea1f4a4060?authentication='
#       url << var1
#       get url
#       last_response.status.should == 500
#     end
#
#
#     it "should return 200 if appointment id is valid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v2/appointment/listbyid/f091c75b-f509-42be-a8d0-130bac1759ff?authentication='
#       url << var1
#       get url
#       # last_response.status.should == 200
#     end
#
#     it "should return 403 error for invalid token" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       url = '/v2/appointment/listbyid/2ae8b08d-5d41-40e5-b068-41803fc689c4?authentication=2345'
#       get url
#       expect(last_response.status) == 403
#     end
#
#
#     it "should return 403 for no token" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       url = '/v2/appointment/listbyid/2ae8b08d-5d41-40e5-b068-41803fc689c4?authentication='
#       get url
#       expect(last_response.status) == 403
#     end
#
#
#     it "should return 200 if request is valid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment/listbyprovider/1234?'
#       url << var1
#       last_response.status.should == 200
#     end
#
#
#   end
#
#   describe "Document API ::" do
#     it "should return 200 if document sources are found" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/documentsources?authentication='
#       url << var1
#       get url
#       last_response.status.should == 200
#     end
#
#   end
#
#   describe "Util Resource API ::" do
#
#     it "should return 200 if gender request is valid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/person/genders?authentication='
#       url << var1
#       get url
#       last_response.status.should == 200
#     end
#
#     it "should return 200 if ethnicities request is valid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/person/ethnicities?authentication='
#       url << var1
#       get url
#       last_response.status.should == 200
#     end
#
#     it "should return 200 if languges request is valid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/person/languages?authentication='
#       url << var1
#       get url
#       last_response.status.should == 200
#     end
#
#     it "should return 200 if races request is valid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/person/races?authentication='
#       url << var1
#       get url
#       last_response.status.should == 200
#     end
#
#     it "should return 200 if maritalstatuses request is valid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/person/maritalstatuses?authentication='
#       url << var1
#       get url
#       last_response.status.should == 200
#     end
#
#     it "should return 200 if religions request is valid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/person/religions?authentication='
#       url << var1
#       get url
#       last_response.status.should == 200
#     end
#
#     it "should return 403 if request is not valid" do
#       get '/v1/patients/patient-2222222222222222222222222222222222222222222222222222222222222222222222222222222222?authentication=1243'
#       last_response.status.should == 403
#     end
#
#     it "should return 403 if request is no auth token" do
#       get '/v1/patients/patient-2222?authentication=12'
#       last_response.status.should == 403
#     end
#
#     it "should return 403 if request is not authorized" do
#       get '/v1/patients/patient-2222?authentication=3333333'
#       last_response.status.should == 403
#       last_response.body.should == '{"error":"Get Business Entity Failed - 403 Forbidden"}'
#     end
#
#     # setup accurate request of patient data
#     it "should return 500 if request is not valid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/patients/patient-1234?authentication='
#       url << var1
#       get url
#       last_response.status.should == 500
#     end
#
#   end
#
#   describe "Appointment API ::" do
#
#     the_appt_id_to_use = '9ff6e7cc-ea0c-4a53-92fb-bf7116c183ee'
#     the_appt_register_id_to_use = ''
#     start_date = Time.now
#     end_date = start_date + 10*60
#
#     it "should return 200 if locations request is valid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment/locations?authentication='
#       url << var1
#       get url
#       last_response.status.should == 200
#     end
#
#
#     it "should return 200 if resources request is valid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment/resources?authentication='
#       url << var1
#       get url
#       last_response.status.should == 200
#     end
#
#     it "should return 200 if appt by date request is valid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment/listbydate/20130724/provider-3538?authentication='
#       url << var1
#       get url
#       last_response.status.should == 200
#     end
#
#     it "should return 200 if appt by provider request is valid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment/listbyprovider/provider-3538?authentication='
#       url << var1
#       get url
#       last_response.status.should == 200
#     end
#
#     it "should return 200 if appt by patient request is valid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment/listbypatient/patient-23d2fe12-3f54-487d-be78-b56d96694d82?authentication='
#       url << var1
#       get url
#       last_response.status.should == 200
#     end
#
#     it "should return 200 if appt by resource request is valid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment/listbyresource/11?authentication='
#       url << var1
#       get url
#       last_response.status.should == 200
#     end
#
#
#     it "should return 400 if request is in invalid provider" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment/create?authentication='
#       url << var1
#
#       var1 = '{
#         "appointment": {
#             "start_time":"'+start_date.to_s+'",
#             "end_time":"'+end_date.to_s+'",
#             "location_id": 2,
#             "nature_of_visit_id": 25470,
#             "provider_id": 222222222222222,
#             "resource_id": "8088",
#             "patients": [
#                 {
#                     "id":  "d380643f-bbd1-4ee1-a3fe-9728e654aeee",
#                     "comments": "patienthasheadache"
#                 }]
#         }
#    }'
#
#
#       post url, var1
#       last_response.body.should match(/Invalid provider presented/)
#     end
#
#     it "should return 400 if request is in invalid location" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment/create?authentication='
#       url << var1
#
#       var1 = '{
#         "appointment": {
#             "start_time":"'+start_date.to_s+'",
#             "end_time":"'+end_date.to_s+'",
#             "location_id": 12,
#             "nature_of_visit_id": 25470,
#             "provider_id": 3538,
#             "resource_id": "8088",
#             "patients": [
#                 {
#                     "id":  "d380643f-bbd1-4ee1-a3fe-9728e654aeee",
#                     "comments": "patienthasheadache"
#                 }]
#         }
#    }'
#       post url, var1
#       last_response.body.should match(/Location Provided Does Not Match Entity/)
#     end
#
#
#
#     it "should return 400 if request is in invalid nature_of_visit" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment/create?authentication='
#       url << var1
#
#       var1 = '{
#         "appointment": {
#             "start_time":"'+start_date.to_s+'",
#             "end_time":"'+end_date.to_s+'",
#             "location_id": 3695,
#             "nature_of_visit_id": 21212,
#             "provider_id": 3538,
#             "resource_id": "8088",
#             "patients": [
#                 {
#                     "id":  "d380643f-bbd1-4ee1-a3fe-9728e654aeee",
#                     "comments": "patienthasheadache"
#                 }]
#         }
#    }'
#
#
#       post url, var1
#       last_response.body.should match(/Nature of Visit Provided Does Not Match Entity/)
#     end
#
#
#     it "should return 400 if request is in invalid resource" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment/create?authentication='
#       url << var1
#
#       var1 = '{
#         "appointment": {
#             "start_time":"'+start_date.to_s+'",
#             "end_time":"'+end_date.to_s+'",
#             "location_id": 3695,
#             "resource_id": 134,
#             "nature_of_visit_id": 25470,
#             "provider_id": 3538,
#             "patients": [
#                 {
#                     "id": "d380643f-bbd1-4ee1-a3fe-9728e654aeee",
#                     "comments": "patienthasheadache"
#                 }]
#         }
#    }'
#
#
#       post url, var1
#       last_response.body.should match(/Resource Provided Does Not Match Entity/)
#     end
#
#     it "should return 400 if request is in invalid patient" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment/create?authentication='
#       url << var1
#
#       var1 = '{
#         "appointment": {
#             "start_time":"'+start_date.to_s+'",
#             "end_time":"'+end_date.to_s+'",
#             "location_id": 1212,
#             "resource_id": 121122,
#             "nature_of_visit_id": 2,
#             "provider_id": 3538,
#             "resource_id": "121313",
#             "patients": [
#                 {
#                     "id": 123,
#                     "comments": "patienthasheadache"
#                 }]
#         }
#    }'
#
#
#       post url, var1
#       last_response.body.should match(/Patient Provided Does Not Match Entity/)
#     end
#
#
#
#
#     it "should return 400 if request is in invalid provider" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment/create?authentication='
#       url << var1
#
#       var1 = '{
#         "appointment": {
#             "start_time":"'+start_date.to_s+'",
#             "end_time":"'+end_date.to_s+'",
#             "location_id": 2,
#             "nature_of_visit_id": 2,
#             "provider_id": 222222222222222,
#             "patients": [
#                 {
#                     "id": 1,
#                     "comments": "patienthasheadache"
#                 }]
#         }
#    }'
#
#
#       post url, var1
#       last_response.status.should == 400
#     end
#
#     it "should return 201 if request is in valid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment/create?authentication='
#       url << var1
#
#       var1 = '{
#         "appointment": {
#             "start_time":"'+start_date.to_s+'",
#             "end_time":"'+end_date.to_s+'",
#             "location_id": 36,
#             "provider_id": 9,
#             "nature_of_visit_id": 53,
#             "resource_id": 67,
#             "patients": [
#                 {
#                     "id": 24044,
#                     "comments": "patient has headache"
#                 }]
#         }
#     }'
#       post url, var1
#       appt_id = JSON.parse(last_response.body)["appointment"]
#       the_appt_id_to_use = appt_id
#       last_response.status.should == 201
#     end
#
#
#     it "should return 200 to delete appointment " do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment/9/'
#       url << the_appt_id_to_use
#       url << '?authentication='
#       url << var1
#       delete url, var1
#       last_response.status.should == 200
#     end
#
#
#     it "should return 400 bad provider to delete appointment " do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment/22222222222222222/'
#       url << the_appt_id_to_use
#       url << '?authentication='
#       url << var1
#
#       delete url, var1
#       the_appt_id_to_use = JSON.parse(last_response.body)["appointment"]
#
#       last_response.status.should == 400
#     end
#
#
#     it "should return 200 to register callback for appointment " do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment/register?authentication='
#       url << var1
#
#       var2 = ' {
#         "notification_active": true,
#         "notification_callback_url": "https://www.hererere.com",
#         "notification_shared_key" : "testings"
#    }'
#
#       post url, var2
#       result = JSON.parse(last_response.body)["notification_callback"]["id"]
#       the_appt_register_id_to_use = result
#       last_response.status.should == 201
#     end
#
#
#     it "should return 201 to update callback for appointment " do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment/register?authentication='
#       url << var1
#
#       var2 = ' { "id": "'
#       var2 << the_appt_register_id_to_use
#       var2 << '", "notification_active": true, "notification_callback_url": "https://www.here.com", "notification_shared_key" : "testingtttttt" }'
#
#       put url, var2
#       last_response.status.should == 200
#     end
#
#     it "should return 200 to delete callback for appointment " do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment/register?authentication='
#       url << var1
#
#       var2 = ' { "id": "'
#       var2 << the_appt_register_id_to_use
#       var2 << '", "notification_active": true, "notification_callback_url": "https://www.here.com" }'
#
#       delete url, var2
#       last_response.status.should == 200
#
#     end
#
#     it "Should return appointment templates" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment_templates?authentication='
#       url << var1
#
#       get url
#       last_response.status.should == 200
#     end
#
#     it "Should return appointment templates by a date" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/appointment_templates_by_dates/2014-08-11?authentication='
#       url << var1
#
#       get url
#       last_response.status.should == 200
#     end
#
#   end
#
#     describe "Patient API ::" do
#
#       the_patient_id_to_use = '24044'
#
#       it "should return 403 if request is not authorized" do
#         var1 = '{"todo":"this"}'
#         post '/v1/patients/create?authentication=3333333', var1
#         last_response.status.should == 403
#         last_response.body.should == '{"error":"Get Business Entity Failed - 403 Forbidden"}'
#       end
#
#       it "should return 400 if request is in valid" do
#         authorize INTERFACE_USER, INTERFACE_PASS
#         post '/v1/service/authenticate'
#         var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#         url = '/v1/patients/create?authentication='
#         url << var1
#
#         var1 = '{"todo":"this"}'
#         put url, var1
#         last_response.status.should == 400
#       end
#
#       it "should return 201 if request is in valid" do
#         authorize INTERFACE_USER, INTERFACE_PASS
#         post '/v1/service/authenticate'
#         var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#         url = '/v1/patients/create?authentication='
#         url << var1
#
#         var1 = '{
#         "patient": {
#             "first_name": "bob",
#             "last_name": "smith",
#             "middle_initial": "E",
#             "email": "no@email.com",
#             "prefix": "mr",
#             "suffix": "jr",
#             "ssn": "123-45-6789",
#             "gender_id": "1",
#             "date_of_birth": "2000-03-12"
#         },
#         "addresses": [{
#             "line1": "123 fake st",
#             "line2": "apt3",
#             "city": "newton",
#             "state_id": "2",
#             "zip_code": "07488",
#             "county_name": "suffolk",
#             "latitude": "",
#             "longitude": "",
#             "country_id": "225"
#         }],
#         "phones": [
#             {
#                 "phone_number": "5552221212",
#                 "phone_type_id": "3",
#                 "extension": "3433"
#             },
#             {
#                 "phone_number": "3332221212",
#                 "phone_type_id": "2",
#                 "extension": "5566"
#             }
#         ]
#    }'
#
#
#         post url, var1
#         #the_patient_id_to_use = JSON.parse(last_response.body)["patient"]
#         valid_regex = /{"patient":"(.*)"}/
#         last_response.body.should =~ (valid_regex)
#         last_response.status.should == 201
#       end
#
#       it "should update the patient" do
#         authorize INTERFACE_USER, INTERFACE_PASS
#         post '/v1/service/authenticate'
#         var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#         url = '/v1/patients/patient-'
#         url << the_patient_id_to_use
#         url << '?authentication='
#         url << var1
#
#         var1 = '{
#         "patient": {
#             "first_name": "Roger",
#             "last_name": "smith",
#             "middle_initial": "E",
#             "email": "no@email.com",
#             "prefix": "mr",
#             "suffix": "jr",
#             "ssn": "123-45-6789",
#             "gender_id": "1",
#             "date_of_birth": "2000-03-12"
#         },
#         "addresses": {
#             "line1": "123 fake st",
#             "line2": "apt3",
#             "city": "newton",
#             "state_code": "ma",
#             "zip_code": "07488",
#             "county_name": "suffolk",
#             "latitude": "",
#             "longitude": "",
#             "country_id": "225"
#         },
#         "phones": [
#             {
#                 "phone_number": "5552221212",
#                 "phone_type_id": "3",
#                 "extension": "3433"
#             },
#             {
#                 "phone_number": "3332221212",
#                 "phone_type_id": "2",
#                 "extension": "5566"
#             }
#         ]
#    }'
#         put url, var1
#         ## todo check response for ROGER
#         last_response.status.should == 200
#       end
#
#       it "should return delete the patient" do
#         authorize INTERFACE_USER, INTERFACE_PASS
#         post '/v1/service/authenticate'
#         var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#         url = '/v1/patients/patient-'
#         url << the_patient_id_to_use
#         url << '?authentication='
#         url << var1
#
#         delete url, var1
#         last_response.status.should == 200
#       end
#
#       it "should return the patient data from search" do
#         authorize INTERFACE_USER, INTERFACE_PASS
#         post '/v1/service/authenticate'
#         var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#         url = 'v1/patients/search?authentication='
#         url << var1
#
#         var1 = '{
#         "limit": 5,
#          "search": [ { "term": "brady"},
#          {"term": "555555555"}]}'
#
#         post url, var1
#         last_response.status.should == 200
#       end
#   end
#
#
#   describe "Providers API ::" do
#
#     it "should return 200 if providers request is valid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = '/v1/provider/list?authentication='
#       url << var1
#       get url
#       last_response.status.should == 200
#     end
#
#   end
#
#
#   describe "Charges API :: " do
#
#     before do
#       stub_memcached
#     end
#
#     it "should return 201 if charges are created" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/charge/patient-'
#       url << '23d2fe12-3f54-487d-be78-b56d96694d82'
#       url << '/create?authentication='
#       url << var1
#
#       var1 = '{"charge": {
#          "provider_id": "9",
#          "icd_indicator": 9,
#          "insurance_profile_id": "",
#          "attending_provider_id": "",
#          "referring_physician_id": "",
#          "supervising_provider_id": "",
#          "authorization_id": "",
#          "clinical_case_id": "",
#          "location_id": "29",
#          "encounter_id": "",
#          "debit_transaction_id": "",
#          "start_time": "2014-01-03",
#          "end_time": "2014-01-03",
#          "units": 1,
#          "procedure_code": "99253",
#          "procedure_short_description": "",
#          "diagnosis1_code": "285.9",
#          "diagnosis1_pointer": 1,
#          "diagnosis2_code": "",
#          "diagnosis2_pointer": "",
#          "diagnosis3_code": "",
#          "diagnosis3_pointer": "",
#          "diagnosis4_code": "",
#          "diagnosis4_pointer": "",
#          "diagnosis5_code": "",
#          "diagnosis5_pointer": "",
#          "diagnosis6_pointer":"",
#          "diagnosis7_code": "",
#          "diagnosis7_pointer": "",
#          "diagnosis8_code": "",
#          "diagnosis8_pointer": "",
#          "date_of_service": "2015-05-01",
#          "modifier1_code": "",
#          "modifier2_code": "",
#          "modifier3_code": "",
#          "modifier4_code": ""
#      },
#      "clinical_case": {
#          "clinical_case_type_id": "1",
#          "effective_from": "1",
#          "effective_to": "1",
#          "onset_date": "1",
#          "hospitalization_date_from": "1",
#          "hospitalization_date_to": "1",
#          "auto_accident_state_id": "1",
#          "newborn_weight": "1",
#          "pregnancy_indicator": "1",
#          "location_id": "1",
#          "accident_type_id": "1",
#          "claim_number": "1",
#          "adjuster_contact_id": "1",
#          "order_date": "1",
#          "initial_treatment_date": "1",
#          "referral_date": "1",
#          "last_seen_date": "1",
#          "acute_manifestation_date": "1"
#      }
# }'
#       post url, var1
#       last_response.status.should == 201
#     end
#
#     it "should return 500 if patient doesnt exist" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/charge/patient-'
#       url << '8697bea1-3a57-4b68-9fc3-1213113'
#       url << '/create?authentication='
#       url << var1
#
#       var1 = '{
#      "charge": {
#          "provider_id": "9",
#          "insurance_profile_id": "",
#          "attending_provider_id": "",
#          "referring_physician_id": "",
#          "supervising_provider_id": "",
#          "authorization_id": "",
#          "clinical_case_id": "",
#          "location_id": "",
#          "encounter_id": "",
#          "debit_transaction_id": "",
#          "start_time": "2014-01-03",
#          "end_time": "2014-01-03",
#          "units": 1,
#          "procedure_code": "99253",
#          "procedure_short_description": "",
#          "diagnosis1_code": "285.9",
#          "diagnosis1_pointer": 1,
#          "diagnosis2_code": "",
#          "diagnosis2_pointer": "",
#          "diagnosis3_code": "",
#          "diagnosis3_pointer": "",
#          "diagnosis4_code": "",
#          "diagnosis4_pointer": "",
#          "diagnosis5_code": "",
#          "diagnosis5_pointer": "",
#          "diagnosis6_pointer":"",
#          "diagnosis7_code": "",
#          "diagnosis7_pointer": "",
#          "diagnosis8_code": "",
#          "diagnosis8_pointer": "",
#          "modifier1_code": "",
#          "modifier2_code": "",
#          "modifier3_code": "",
#          "modifier4_code": ""
#      },
#      "clinical_case": {
#          "clinical_case_type_id": "1",
#          "effective_from": "1",
#          "effective_to": "1",
#          "onset_date": "1",
#          "hospitalization_date_from": "1",
#          "hospitalization_date_to": "1",
#          "auto_accident_state_id": "1",
#          "newborn_weight": "1",
#          "pregnancy_indicator": "1",
#          "location_id": "1",
#          "accident_type_id": "1",
#          "claim_number": "1",
#          "adjuster_contact_id": "1",
#          "order_date": "1",
#          "initial_treatment_date": "1",
#          "referral_date": "1",
#          "last_seen_date": "1",
#          "acute_manifestation_date": "1"
#      }
# }'
#       post url, var1
#       last_response.status.should == 500
#     end
#
# #    it "should return 500 if clinical is invalid" do
# #      authorize INTERFACE_USER, INTERFACE_PASS
# #      post '/v1/service/authenticate'
# #      var1 = CGI::escape(JSON.parse(last_response.body)["token"])
# #      url = ''
# #      url << '/v1/charge/patient-'
# #      url << '8697bea1-3a57-4b68-9fc3-2382c5fa3207'
# #      url << '/create?authentication='
# #      url << var1
# #
# #      var1 = '{
# #     "charge": {
# #         "provider_id": "4817",
# #         "insurance_profile_id": "",
# #         "attending_provider_id": "",
# #         "referring_physician_id": "",
# #         "supervising_provider_id": "",
# #         "authorization_id": "",
# #         "clinical_case_id": "1231221322",
# #         "location_id": "",
# #         "encounter_id": "",
# #         "debit_transaction_id": "",
# #         "start_time": "2014-01-03",
# #         "end_time": "2014-01-03",
# #         "units": 1,
# #         "procedure_code": "99253",
# #         "procedure_short_description": "",
# #         "diagnosis1_code": "285.9",
# #         "diagnosis1_pointer": 1,
# #         "diagnosis2_code": "",
# #         "diagnosis2_pointer": "",
# #         "diagnosis3_code": "",
# #         "diagnosis3_pointer": "",
# #         "diagnosis4_code": "",
# #         "diagnosis4_pointer": "",
# #         "diagnosis5_code": "",
# #         "diagnosis5_pointer": "",
# #         "diagnosis6_pointer":"",
# #         "diagnosis7_code": "",
# #         "diagnosis7_pointer": "",
# #         "diagnosis8_code": "",
# #         "diagnosis8_pointer": "",
# #         "modifier1_code": "",
# #         "modifier2_code": "",
# #         "modifier3_code": "",
# #         "modifier4_code": ""
# #     },
# #     "clinical_case": {
# #         "clinical_case_type_id": "1",
# #         "effective_from": "1",
# #         "effective_to": "1",
# #         "onset_date": "1",
# #         "hospitalization_date_from": "1",
# #         "hospitalization_date_to": "1",
# #         "auto_accident_state_id": "1",
# #         "newborn_weight": "1",
# #         "pregnancy_indicator": "1",
# #         "location_id": "1",
# #         "accident_type_id": "1",
# #         "claim_number": "1",
# #         "adjuster_contact_id": "1",
# #         "order_date": "1",
# #         "initial_treatment_date": "1",
# #         "referral_date": "1",
# #         "last_seen_date": "1",
# #         "acute_manifestation_date": "1"
# #     }
# #}'
# #      post url, var1
# #      last_response.status.should == 500
# #    end
#
#     it "should return 403 if charges token invalid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/charge/patient-'
#       url << '8697bea1-3a57-4b68-9fc3-1213113'
#       url << '/create?authentication=1221'
#       url << var1
#
#       var1 = '{
#      "charge": {
#          "provider_id": "4817",
#          "insurance_profile_id": "",
#          "attending_provider_id": "",
#          "referring_physician_id": "",
#          "supervising_provider_id": "",
#          "authorization_id": "",
#          "clinical_case_id": "",
#          "location_id": "",
#          "encounter_id": "",
#          "debit_transaction_id": "",
#          "start_time": "2014-01-03",
#          "end_time": "2014-01-03",
#          "units": 1,
#          "procedure_code": "99253",
#          "procedure_short_description": "",
#          "diagnosis1_code": "285.9",
#          "diagnosis1_pointer": 1,
#          "diagnosis2_code": "",
#          "diagnosis2_pointer": "",
#          "diagnosis3_code": "",
#          "diagnosis3_pointer": "",
#          "diagnosis4_code": "",
#          "diagnosis4_pointer": "",
#          "diagnosis5_code": "",
#          "diagnosis5_pointer": "",
#          "diagnosis6_pointer":"",
#          "diagnosis7_code": "",
#          "diagnosis7_pointer": "",
#          "diagnosis8_code": "",
#          "diagnosis8_pointer": "",
#          "modifier1_code": "",
#          "modifier2_code": "",
#          "modifier3_code": "",
#          "modifier4_code": ""
#      },
#      "clinical_case": {
#          "clinical_case_type_id": "1",
#          "effective_from": "1",
#          "effective_to": "1",
#          "onset_date": "1",
#          "hospitalization_date_from": "1",
#          "hospitalization_date_to": "1",
#          "auto_accident_state_id": "1",
#          "newborn_weight": "1",
#          "pregnancy_indicator": "1",
#          "location_id": "1",
#          "accident_type_id": "1",
#          "claim_number": "1",
#          "adjuster_contact_id": "1",
#          "order_date": "1",
#          "initial_treatment_date": "1",
#          "referral_date": "1",
#          "last_seen_date": "1",
#          "acute_manifestation_date": "1"
#      }
# }'
#       post url, var1
#       last_response.status.should == 403
#     end
#
#     it "should return 400 if charges location is invalid" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/charge/patient-'
#       url << '23d2fe12-3f54-487d-be78-b56d96694d82'
#       url << '/create?authentication='
#       url << var1
#
#       var1 = '{
#      "charge": {
#          "provider_id": "4817",
#          "insurance_profile_id": "",
#          "attending_provider_id": "",
#          "referring_physician_id": "",
#          "supervising_provider_id": "",
#          "authorization_id": "",
#          "clinical_case_id": "",
#          "location_id": "1213131",
#          "encounter_id": "",
#          "debit_transaction_id": "",
#          "start_time": "2014-01-03",
#          "end_time": "2014-01-03",
#          "units": 1,
#          "procedure_code": "99253",
#          "procedure_short_description": "",
#          "diagnosis1_code": "285.9",
#          "diagnosis1_pointer": 1,
#          "diagnosis2_code": "",
#          "diagnosis2_pointer": "",
#          "diagnosis3_code": "",
#          "diagnosis3_pointer": "",
#          "diagnosis4_code": "",
#          "diagnosis4_pointer": "",
#          "diagnosis5_code": "",
#          "diagnosis5_pointer": "",
#          "diagnosis6_pointer":"",
#          "diagnosis7_code": "",
#          "diagnosis7_pointer": "",
#          "diagnosis8_code": "",
#          "diagnosis8_pointer": "",
#          "modifier1_code": "",
#          "modifier2_code": "",
#          "modifier3_code": "",
#          "modifier4_code": ""
#      },
#      "clinical_case": {
#          "clinical_case_type_id": "1",
#          "effective_from": "1",
#          "effective_to": "1",
#          "onset_date": "1",
#          "hospitalization_date_from": "1",
#          "hospitalization_date_to": "1",
#          "auto_accident_state_id": "1",
#          "newborn_weight": "1",
#          "pregnancy_indicator": "1",
#          "location_id": "1",
#          "accident_type_id": "1",
#          "claim_number": "1",
#          "adjuster_contact_id": "1",
#          "order_date": "1",
#          "initial_treatment_date": "1",
#          "referral_date": "1",
#          "last_seen_date": "1",
#          "acute_manifestation_date": "1"
#      }
# }'
#       post url, var1
#       last_response.status.should == 400
#
#     end
#
#     it "should return 400 if charges provider is invalid" do
#
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/charge/patient-'
#       url << '23d2fe12-3f54-487d-be78-b56d96694d82'
#       url << '/create?authentication='
#       url << var1
#
#       var1 = '{
#      "charge": {
#          "provider_id": "12134332",
#          "insurance_profile_id": "",
#          "attending_provider_id": "",
#          "referring_physician_id": "",
#          "supervising_provider_id": "",
#          "authorization_id": "",
#          "clinical_case_id": "",
#          "location_id": "",
#          "encounter_id": "",
#          "debit_transaction_id": "",
#          "start_time": "2014-01-03",
#          "end_time": "2014-01-03",
#          "units": 1,
#          "procedure_code": "99253",
#          "procedure_short_description": "",
#          "diagnosis1_code": "285.9",
#          "diagnosis1_pointer": 1,
#          "diagnosis2_code": "",
#          "diagnosis2_pointer": "",
#          "diagnosis3_code": "",
#          "diagnosis3_pointer": "",
#          "diagnosis4_code": "",
#          "diagnosis4_pointer": "",
#          "diagnosis5_code": "",
#          "diagnosis5_pointer": "",
#          "diagnosis6_pointer":"",
#          "diagnosis7_code": "",
#          "diagnosis7_pointer": "",
#          "diagnosis8_code": "",
#          "diagnosis8_pointer": "",
#          "modifier1_code": "",
#          "modifier2_code": "",
#          "modifier3_code": "",
#          "modifier4_code": ""
#      },
#      "clinical_case": {
#          "clinical_case_type_id": "1",
#          "effective_from": "1",
#          "effective_to": "1",
#          "onset_date": "1",
#          "hospitalization_date_from": "1",
#          "hospitalization_date_to": "1",
#          "auto_accident_state_id": "1",
#          "newborn_weight": "1",
#          "pregnancy_indicator": "1",
#          "location_id": "1",
#          "accident_type_id": "1",
#          "claim_number": "1",
#          "adjuster_contact_id": "1",
#          "order_date": "1",
#          "initial_treatment_date": "1",
#          "referral_date": "1",
#          "last_seen_date": "1",
#          "acute_manifestation_date": "1"
#      }
# }'
#       post  url, var1
#       last_response.status.should == 400
#
#     end
#
#     it "should return 400 if authorization is invalid" do
#
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/charge/patient-'
#       url << '23d2fe12-3f54-487d-be78-b56d96694d82'
#       url << '/create?authentication='
#       url << var1
#
#       var1 = '{
#      "charge": {
#          "provider_id": "12134332",
#          "insurance_profile_id": "",
#          "attending_provider_id": "",
#          "referring_physician_id": "",
#          "supervising_provider_id": "",
#          "authorization_id": "124343",
#          "clinical_case_id": "",
#          "location_id": "",
#          "encounter_id": "",
#          "debit_transaction_id": "",
#          "start_time": "2014-01-03",
#          "end_time": "2014-01-03",
#          "units": 1,
#          "procedure_code": "99253",
#          "procedure_short_description": "",
#          "diagnosis1_code": "285.9",
#          "diagnosis1_pointer": 1,
#          "diagnosis2_code": "",
#          "diagnosis2_pointer": "",
#          "diagnosis3_code": "",
#          "diagnosis3_pointer": "",
#          "diagnosis4_code": "",
#          "diagnosis4_pointer": "",
#          "diagnosis5_code": "",
#          "diagnosis5_pointer": "",
#          "diagnosis6_pointer":"",
#          "diagnosis7_code": "",
#          "diagnosis7_pointer": "",
#          "diagnosis8_code": "",
#          "diagnosis8_pointer": "",
#          "modifier1_code": "",
#          "modifier2_code": "",
#          "modifier3_code": "",
#          "modifier4_code": ""
#      },
#      "clinical_case": {
#          "clinical_case_type_id": "1",
#          "effective_from": "1",
#          "effective_to": "1",
#          "onset_date": "1",
#          "hospitalization_date_from": "1",
#          "hospitalization_date_to": "1",
#          "auto_accident_state_id": "1",
#          "newborn_weight": "1",
#          "pregnancy_indicator": "1",
#          "location_id": "1",
#          "accident_type_id": "1",
#          "claim_number": "1",
#          "adjuster_contact_id": "1",
#          "order_date": "1",
#          "initial_treatment_date": "1",
#          "referral_date": "1",
#          "last_seen_date": "1",
#          "acute_manifestation_date": "1"
#      }
# }'
#       post  url, var1
#       last_response.status.should == 400
#
#     end
#
#   end
#
#   describe "Simple Charge API ::" do
#     it "should return 201 if a simple charge is created" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/simple_charge/patient-'
#       url << '23d2fe12-3f54-487d-be78-b56d96694d82'
#       url << '/create?authentication='
#       url << var1
#
#       var1 = '  {
#       "debit": {
#       "entered_at": "",
#       "posting_date": "",
#       "effective_date": "",
#       "period_closed_date": "",
#       "amount": "123",
#       "balance": "0",
#       "value": "111",
#       "value_balance": "0",
#       "batch_number": "",
#       "date_first_statement": "",
#       "date_last_statement": "",
#       "statement_count": "",
#       "note_set_id": "",
#       "document_set_id": "",
#       "transaction_status": ""
#   },
#       "simple_charge": {
#       "provider_id": "57",
#       "location_id": "3695",
#       "units": "1",
#       "patient_payments_applied": "100",
#       "patient_adjustments_applied": "0",
#       "simple_charge_type": "25462",
#       "description": "Simple Charge Test"
#   }
#   }'
#       post  url, var1
#       last_response.status.should == 201
#
#     end
#   end
#
#
#
#   describe "Should return Charges" do
#     patient_id_to_use = '7517691'
#
#     it "should return 200 if charges are returned" do
#
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/charges/'
#       url << patient_id_to_use
#       url << '?authentication='
#       url << var1
#
#       get url
#       last_response.status.should == 200
#
#     end
#
#     it "should return 500 if invalid patient" do
#
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/charges/'
#       url << '9817421389'
#       url << '?authentication='
#       url << var1
#
#       get url
#       last_response.status.should == 500
#
#     end
#
#     it "should return 200 if no charges exist" do
#
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/charges/'
#       url << '7517722'
#       url << '?authentication='
#       url << var1
#
#       get url
#       last_response.status.should == 200
#
#     end
#
#
#     it "should return 500 if patient is not in entity" do
#
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/charges/'
#       url << '12982748327432'
#       url << '?authentication='
#       url << var1
#
#       get url
#       last_response.status.should == 500
#
#     end
#
#     it "should return 200 if simple charges are found" do
#
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/simple_charge_types?authentication='
#       url << var1
#
#       get url
#       last_response.status.should == 200
#
#     end
#
#
#   end
#
#   describe "Appointment Templates::" do
#     it "should return appointment templates" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/appointment_templates?authentication='
#       url << var1
#       get url
#       last_response.status.should == 200
#     end
#
#     it "should return appointment templates" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/appointment_templates_by_dates/20141010?authentication='
#       url << var1
#       get url
#       last_response.status.should == 200
#     end
#
#     it "should return 500 for appointment templates" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/appointment_templates_by_dates/1240?authentication='
#       url << var1
#       get url
#       last_response.status.should == 500
#     end
#
#     it "should return 200 for appointment templates by location" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/appointment_templates/find_by_location/33?authentication='
#       url << var1
#       get url
#       last_response.status.should == 200
#     end
#
#     it "should return 200 for appointment templates by resource" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/appointment_templates/find_by_resource/7?authentication='
#       url << var1
#       get url
#       last_response.status.should == 200
#     end
#
#     it "should return 200 for find_nature_of_visit tied to a template" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/appointment_templates/find_nature_of_visit/37583?authentication='
#       url << var1
#       get url
#       last_response.status.should == 200
#     end
#
#
#     it "should return empty array for invalid template id" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/appointment_templates/find_nature_of_visit/123321334545?authentication='
#       url << var1
#       get url
#
#       puts last_response.body
#       JSON.parse(last_response.body).should == []
#     end
#
#     it "should return empty array for template tied to another BE" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/appointment_templates/find_nature_of_visit/24?authentication='
#       url << var1
#       get url
#       JSON.parse(last_response.body).should == []
#     end
#
#   end
#
#   describe "Appointment Blockouts::" do
#      it "should return appointment blockouts by resource and date" do
#        authorize INTERFACE_USER, INTERFACE_PASS
#        post '/v1/service/authenticate'
#        var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#        url = ''
#        url << 'v1/appointmentblockouts/listbyresourceanddate/7/date/20140421?authentication='
#        url << var1
#        url << '&include_appointments=true'
#        get url
#        last_response.status.should == 200
#      end
#
#      it "should return 500 appointment blockouts by resource and invalid date" do
#        authorize INTERFACE_USER, INTERFACE_PASS
#        post '/v1/service/authenticate'
#        var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#        url = ''
#        url << 'v1/appointmentblockouts/listbyresourceanddate/7/date/2010421?authentication='
#        url << var1
#        url << '&include_appointments=true'
#        get url
#        last_response.status.should == 500
#      end
#
#
#      it "should return appointment blockouts by location and date" do
#        authorize INTERFACE_USER, INTERFACE_PASS
#        post '/v1/service/authenticate'
#        var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#        url = ''
#        url << '/v1/appointmentblockouts/listbylocationanddate/33/date/20100906?authentication='
#        url << var1
#        get url
#        last_response.status.should == 200
#      end
#
#      it "should return 500 appointment blockouts by location and invalid date" do
#        authorize INTERFACE_USER, INTERFACE_PASS
#        post '/v1/service/authenticate'
#        var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#        url = ''
#        url << '/v1/appointmentblockouts/listbylocationanddate/33/date/2100906?authentication='
#        url << var1
#        url << '&include_appointments=true'
#        get url
#        last_response.status.should == 500
#      end
#
#      it "should return appointment blockouts by location, resource, and date" do
#        authorize INTERFACE_USER, INTERFACE_PASS
#        post '/v1/service/authenticate'
#        var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#        url = ''
#        url << '/v1/schedule/20100901/getblockouts/33/11?authentication='
#        url << var1
#        get url
#        last_response.status.should == 200
#      end
#
#      it "should return 500 for appointment blockouts by location, resource, and date" do
#        authorize INTERFACE_USER, INTERFACE_PASS
#        post '/v1/service/authenticate'
#        var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#        url = ''
#        url << '/v1/schedule/2010901/getblockouts/33/11?authentication='
#        url << var1
#        get url
#        last_response.status.should ==500
#      end
#
#
#   end
#
#   describe "Clinical API Services::" do
#       it "should create problem set for patient" do
#         authorize INTERFACE_USER, INTERFACE_PASS
#         post '/v1/service/authenticate'
#         var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#         url = ''
#         url << 'v1/patients/c7fd9c2f-28ce-41e3-a4f4-1bee56e3e7f0/problems/create?authentication='
#         url << var1
#
#         var1 = '{
#         "problem": [
#             {
#                 "snomed_code": "161891005",
#                 "icd9": "724.5",
#                 "icd_indicator": 9,
#                 "name": "Backache unspecified",
#                 "description": "Backache (finding)",
#                 "onset_at": "2011-01-28",
#                 "status": "A"
#             }
#         ]
#       }'
#       post url, var1
#       last_response.status.should == 201
#       end
#
#       it "should create allergies for patient" do
#         authorize INTERFACE_USER, INTERFACE_PASS
#         post '/v1/service/authenticate'
#         var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#         url = ''
#         url << 'v1/patients/c7fd9c2f-28ce-41e3-a4f4-1bee56e3e7f0/allergies/create?authentication='
#         url << var1
#
#         var1 = '{
#           "allergy": [
#            {
#             "rx_norm_code": "196468",
#             "allergen_type_id": "2",
#             "onset_at": "2003-10-09",
#             "name": "Cardura",
#             "status": "A",
#             "reaction": [
#                 {
#                     "description":"testing",
#                     "severity_id": "4",
#                     "reaction_id": "8"
#                 }
#             ]
#         }
#       ]
#     }'
#         post url, var1
#         last_response.status.should == 201
#       end
#
#       it "should create immunizations for patient"  do
#         authorize INTERFACE_USER, INTERFACE_PASS
#         post '/v1/service/authenticate'
#         var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#         url = ''
#         url << 'v1/patients/c7fd9c2f-28ce-41e3-a4f4-1bee56e3e7f0/immunizations/create?authentication='
#         url << var1
#
#         var1 = '{"immunization": [
#             {
#             "immunization_name": "DTaP",
#             "immunization_description": "DTaP",
#             "immunization_code": "20",
#             "vaccine_manufacturer_name": "ABBOTT LABORATORIES",
#             "administered_at": "2011-02-01",
#             "status": "A",
#             "vaccine_administration_quantity": "0.5",
#             "vaccine_administration_quantity_uom": "mL",
#             "vaccine_manufacturer_code": "AB",
#             "route_description": "IM"}]}'
#
#         post url, var1
#         last_response.status.should == 201
#       end
#
#       it "should create medication for patient"  do
#         authorize INTERFACE_USER, INTERFACE_PASS
#         post '/v1/service/authenticate'
#         var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#         url = ''
#         url << 'v1/patients/c7fd9c2f-28ce-41e3-a4f4-1bee56e3e7f0/medications/create?authentication='
#         url << var1
#
#         var1 = '{
#             "medication": [
#             {
#                 "drug_name": "A & D Barrier",
#             "effective_from": "2010-06-02",
#             "effective_to": "2010-06-02",
#             "drug_description": "A & D Barrier Ointment 1 Application TP TID",
#             "route_description": "TP",
#             "status": "A",
#             "frequency_description": "TID",
#             "dose": "1 Application",
#             "is_substitution_permitted": "true"
#         }
#         ]
#         }'
#         post url, var1
#         last_response.status.should == 201
#       end
#   end
#
#   describe "Util Helper API Methods ::" do
#
#     it "should return 403 if bad authentication token" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/get/locations?authentication=12'
#
#       get url
#       last_response.status.should == 403
#     end
#
#     it "should return 200 location list is found" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/get/locations?authentication='
#       url << var1
#
#       get url
#       last_response.status.should == 200
#     end
#
#     it "should return 200 nature of visits found" do
#       authorize INTERFACE_USER, INTERFACE_PASS
#       post '/v1/service/authenticate'
#       var1 = CGI::escape(JSON.parse(last_response.body)["token"])
#       url = ''
#       url << '/v1/nature_of_visits?authentication='
#       url << var1
#
#       get url
#       last_response.status.should == 200
#     end
#
#
#   end
#
# end