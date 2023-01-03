module ActCertification
  Types = {
      Goal: "multipatient_list_goals",
      Immunization: "multipatient_list_immunizations",
      Condition: "multipatient_list_conditions",
      Patient: "multipatient_list_patients",
      CarePlan: "multipatient_list_care_plans",
      CareTeam: "multipatient_list_care_team",
      Device: "multipatient_list_medical_devices",
      Procedure: "multipatient_list_procedures",
      MedicationRequest: "multipatient_list_medication_orders",
      Medication: "multipatient_list_medications",
      DocumentReference: "multipatient_list_document_reference",
      AllergyIntolerance: "multipatient_list_allergy_intolerance",
      Observation: {
        "5778-6" => "multipatient_list_lab_results",
        "72166-2" => "multipatient_list_observations_smoking_status",
        "1" => "multipatient_list_observations"
      },
      DiagnosticReport: "multipatient_list_diagnostic_reports",
      Location: "multipatient_list_locations",
      Encounter: "",
      Organization: "multipatient_list_organization",
      Provenance: "multi_patient_provenance",
      Practitioner: "multipatient_list_practitioners"

  }
end