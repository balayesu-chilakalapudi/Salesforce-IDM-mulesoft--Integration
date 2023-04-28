public class DPM_EmployeeJobPositionTriggerHelper {
/*
* Name      : DPM_EmployeeJobPositionTriggerHelper
* Purpose   : Helper class for DPM Employee Job Position Trigger  
* Author    : Krishna Singh
* Date      : 29-Sept-2020
* 
* */
    public static void updatePrimaryPositionOnPersonRole(List<DPM_EmployeeJobPosition__c> lstEmpJobPositions) {
        List<DPM_EmployeeJobPosition__c> lstEmpJobPositionsToProcess = new List<DPM_EmployeeJobPosition__c>();
        for(DPM_EmployeeJobPosition__c empJobPosition : lstEmpJobPositions) {
            if(empJobPosition.DPM_Primary_Position__c) {
                lstEmpJobPositionsToProcess.add(empJobPosition);
            }
        }
        if(!lstEmpJobPositionsToProcess.isEmpty()) {
            Map<String,RE_Job_to_Persona_map__mdt> mapJobPositionToPersona = getPersonaMap();
            List<RE_Person_Role__c> lstPersonRolesToUpdate = new List<RE_Person_Role__c>();
            for(DPM_EmployeeJobPosition__c empJobPosition : lstEmpJobPositionsToProcess) {
                lstPersonRolesToUpdate.add(
                    new RE_Person_Role__c(
                        Id = empJobPosition.DPM_Person_Role__c,
                        RE_Pos_Active_Date__c = empJobPosition.DPM_Position_Start_Date__c,
                        RE_Pos_NonActive_Date__c = empJobPosition.DPM_Position_End_Date__c,
                        RE_Employee_Position__c = empJobPosition.DPM_Position_Title__c,
                        RE_Persona__c = (mapJobPositionToPersona.keyset().contains(empJobPosition.DPM_Position_Title__c)?mapJobPositionToPersona.get(empJobPosition.DPM_Position_Title__c).Persona__c:NULL),
                        RE_Psn_Pos_Abbr__c = (mapJobPositionToPersona.keyset().contains(empJobPosition.DPM_Position_Title__c)?mapJobPositionToPersona.get(empJobPosition.DPM_Position_Title__c).Job_Abbr__c:NULL),
                        RE_Position_Active__c = ((empJobPosition.DPM_Position_End_Date__c == NULL || empJobPosition.DPM_Position_End_Date__c>=System.today())?True:False)
                    )
                );
            }
            if(!lstPersonRolesToUpdate.isEmpty()) {
                try {
                	update lstPersonRolesToUpdate;
                }
                catch (Exception e) {
                    system.debug('error-->'+e.getMessage());
                }
            }
        }
    }
    public static Map<String,RE_Job_to_Persona_map__mdt> getPersonaMap() {
        Map<String,RE_Job_to_Persona_map__mdt> mapJobPositionToPersona = new Map<String,RE_Job_to_Persona_map__mdt>();
        for(RE_Job_to_Persona_map__mdt jobToPersonaMap : [SELECT Persona__c, Job_Abbr__c, Label FROM RE_Job_to_Persona_map__mdt]) {
            mapJobPositionToPersona.put(jobToPersonaMap.Label,jobToPersonaMap);
        }
        return mapJobPositionToPersona;
    }
}