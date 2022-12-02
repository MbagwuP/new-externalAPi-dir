module ActCertification
  Types = {
      Goal: "multipatient_list_goals",
      Immunization: "multipatient_list_immunizations",
      Condition: "multipatient_list_conditions",
      Patient: "multipatient_list_patients",
      Careplan: "multipatient_list_care_plans",
      Careteam: "multipatient_list_care_team",
      Device: "multipatient_list_medical_devices",
      Procedure: "multipatient_list_procedures",
      Medication: "multipatient_list_medication_orders",
      Documentreference: "multipatient_list_document_reference",
      Allergyintolerances: "multipatient_list_allergy_intolerance",
      Observation: {
        "5778-6" => "multipatient_list_lab_results",
        "72166-2" => "multipatient_list_observations_smoking_status",
        "1" => "multipatient_list_observations"
      },
      Diagnosticreport: "multipatient_list_diagnostic_reports",
      Location: "",
      Encounter: "",
      Organization: "multipatient_list_organization"


  }
end