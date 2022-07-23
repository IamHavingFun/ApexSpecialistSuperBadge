public with sharing class MaintenanceRequestHelper {
    
    public static void updateWorkOrders(List<Case> cases) {
        // TODO: Complete the method to update workorders
        // Collect the id of the Maintenance Request record to process
        Set<Id> ids = new Set<Id>();

        // Get the Maintenance Request Ids based on the Type = Repair or Routine Maintenance and Status is closed
        for (Case c : cases) {
            if ( (c.Type == 'Repair' || c.Type == 'Routine Maintenance') && c.Status == 'Closed') {
                ids.add(c.Id);
            }
        }

        // When the Maintenance Request of Type (Repair or Routine Maintenance) - (Status) is Closed
        // Create a new Maintenance Request for a future Routine Maintenance checkup
        if (!ids.isEmpty()) {
            Map<Id, Case> closedCaseByIds = new Map<Id, Case>([SELECT Id, Vehicle__c,
            ( SELECT Id, Equipment__c, Quantity__c, Equipment__r.Maintenance_Cycle__c FROM Equipment_Maintenance_Items__r)
            FROM Case WHERE Id IN :ids]);

            /**
             * If multiple pieces of equipment are used in the maintenance request,
             * define the due date by applying the shortest maintenance cycle to today’s date.
             * */

            // Map to hold aggregated result of Maintenance cycle
            Map<Id, Decimal> idToMinCycle = new Map<Id, Decimal>();

            // Aggregate to get the Minimum of Maintenance Cycle days
            AggregateResult[] aggregateResults = [SELECT Maintenance_Request__c, MIN(Equipment__r.Maintenance_Cycle__c) Cycle
            FROM Equipment_Maintenance_Item__c WHERE Maintenance_Request__c IN : ids GROUP BY Maintenance_Request__c];

            // Build a Map to get the Min Maintenance Cycles with Maintenance Request Id
            for (AggregateResult ar : aggregateResults){
                idToMinCycle.put((Id) ar.get('Maintenance_Request__c') , (Decimal) ar.get('Cycle'));
            }

            /*********************** */

            // List to hold the new Case to insert
            List<Case> newCases = new List<Case>();

            // Loop through the list of cases from the Map
            for (Case aCase : closedCaseByIds.values()) {
                Case newCase = new Case();
                newCase.Type = 'Routine Maintenance';
                newCase.Status = 'New';
                newCase.Vehicle__c = aCase.Vehicle__c;
                newCase.Subject = 'Auto Routine Maintenance';
                newCase.Date_Reported__c = Date.today();
                newCase.ParentId = aCase.Id;

                // get shortest maintenance cycle to today’s date
                /*
                if (idToMinCycle.containsKey(aCase.Id)) {
                    newCase.Date_Due__c = Date.today().addDays((Integer) idToMinCycle.get(aCase.Id));
                } else {
                    newCase.Date_Due__c = Date.today().addDays(0); // if there's no min cycle then add 0
                }
                 */
                newCase.Date_Due__c = Date.today().addDays(idToMinCycle.containsKey(aCase.Id) ? (Integer) idToMinCycle.get(aCase.Id) : 0 );
                newCases.add(newCase);
            }

            // Insert auto Maintenance Request
            if (newCases.size() > 0) {
                insert newCases;
            }

            // Prep related Equipment Maintenance Item
            List<Equipment_Maintenance_Item__c> equipmentMaintenanceItems = new List<Equipment_Maintenance_Item__c>();
            for (Case nCase : newCases) {
                for (Equipment_Maintenance_Item__c item : closedCaseByIds.get(nCase.ParentId).Equipment_Maintenance_Items__r) {
                    Equipment_Maintenance_Item__c equipmentMaintenanceItem = item.clone();
                    equipmentMaintenanceItem.Maintenance_Request__c = nCase.Id;
                    equipmentMaintenanceItems.add(equipmentMaintenanceItem);
                }
            }

            // Insert auto related Equipment Maintenance Item
            if (equipmentMaintenanceItems.size() > 0) {
                insert equipmentMaintenanceItems;
            }

        }

    }        
    
}