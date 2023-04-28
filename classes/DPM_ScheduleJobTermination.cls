public class DPM_ScheduleJobTermination implements schedulable {        
    public String strCDSID;
    public String strNewValue;
    public String strOldValue;
    public String strField;
    public String personRoleId;
    
    public DPM_ScheduleJobTermination(String strCDSID, String strNewValue, String strOldValue, String strField,string personRoleId){           	
        this.strCDSID=strCDSID;
        this.strNewValue=strNewValue;
        this.strOldValue=strOldValue;
        this.strField=strField;
        this.personRoleId=personRoleId;
    }
    
    public void execute(SchedulableContext sc){   
        System.enqueueJob(new DPM_JobPositionUpdateQueue(strCDSID,strNewValue,strOldValue,strField,personRoleId));
    }
}