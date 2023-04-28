public class DPM_JobPositionUpdateQueue implements Queueable {
    public String strCDSID;
    public String strNewValue;
    public String strOldValue;
    public String strField;
    public String personRoleId;
    
    public DPM_JobPositionUpdateQueue(String strCDSID, String strNewValue, String strOldValue, String strField,string personRoleId){            
        this.strCDSID=strCDSID;
        this.strNewValue=strNewValue;
        this.strOldValue=strOldValue;
        this.strField=strField;
        this.personRoleId=personRoleId; 
    }
    
    public void execute(QueueableContext context) {
        runCallout(strCDSID,strNewValue,strOldValue,strField,personRoleId);
    }
    
    @future(Callout=true)
    public static void runCallout(String strCDSID, String strNewValue, String strOldValue, String strField,string personRoleId){
        DPM_PersonnelMasterServices.DPM_LogData logWrapObj=DPM_PersonnelMasterServices.callIDMToUpdateEmployeeData(strCDSID,strNewValue,strOldValue,strField,personRoleId);
        if(logWrapObj!=null &&
           logWrapObj.objDPMLog!=null){
               insert logWrapObj.objDPMLog;
           }
    }        
}