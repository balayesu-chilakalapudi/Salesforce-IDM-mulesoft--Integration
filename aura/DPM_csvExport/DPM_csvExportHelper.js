({
    convertListToCSV : function(component, sObjectList){
        //console.log('sObjectList:'+JSON.stringify(sObjectList));
        if (sObjectList == null || sObjectList.length == 0) {
            return null; // 
        }

        // CSV file parameters.
        var columnEnd = ',';
        var lineEnd =  '\n';

        // Get the CSV header from the list.
        var keys = new Set();
        sObjectList.forEach(function (record) {
            Object.keys(record).forEach(function (key) {
                if(!key.includes('__r') && !key.includes('Id') && !key.includes('DPM_Person_Role__c') && !key.includes('RE_Contact__c')){
                    keys.add(key);
                }
            });
        });

        // 
        keys = Array.from(keys);

        var csvString = '';
        csvString += component.get("v.fileHeader");
       // csvString += 'NAME,STORE NAME - ID,JOB POSITION,ACTIVE/TERMINATED,POSITION START DATE,WORK EMAIL,COUNTRY';
        //keys.join(columnEnd);
        csvString += lineEnd;

        for(var i=0; i < sObjectList.length; i++){
            var counter = 0;

            for(var sTempkey in keys) {
                var skey = keys[sTempkey] ;

                // add , after every value except the first.
                if(counter > 0){
                    csvString += columnEnd;
                }
               // console.log('sObjectList[i][skey]:'+sObjectList[i][skey]);
                // If the column is undefined, leave it as blank in the CSV file.
                var value = (sObjectList[i][skey] === undefined || sObjectList[i][skey] ==='' || sObjectList[i][skey] ===null) ? 'Not Available' : sObjectList[i][skey];
                csvString += '"'+ value +'"';
                counter++;
            }

            csvString += lineEnd;
        }

        return csvString;
    },
})