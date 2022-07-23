@IsTest
public with sharing class MaintenanceRequestHelperTest {
    // implement test code here

    // create and return a test vehicle
    private static Vehicle__c createVehicle(){
        Vehicle__c vehicle = new Vehicle__c();
        vehicle.Name = 'My Testing Vehicle';
        return  vehicle;
    }

    // create and return a test Equipment
    private static Product2 createEquipment(){
        Product2 product2 = new Product2();
        product2.Name = 'My Testing Equipment';
        product2.Lifespan_Months__c = 8;
        product2.Maintenance_Cycle__c = 90;
        product2.Replacement_Part__c = true;
        return  product2;
    }

    // create and return a test Maintenance Request (Case)
    private  static Case createMaintenanceRequest(Id vehicleId){
        Case testCase = new Case();
        testCase.Type = 'Repair';
        testCase.Status = 'New';
        testCase.Subject = 'Testing Subject';
        testCase.Vehicle__c = vehicleId;
        return  testCase;
    }

    // create and return a test Equipment Maintenance Item
    private static Equipment_Maintenance_Item__c createEquipmentMaintenanceItem(Id equipmentId, Id maintenanceRequestId){
        Equipment_Maintenance_Item__c maintenanceItem = new Equipment_Maintenance_Item__c();
        maintenanceItem.Maintenance_Request__c = maintenanceRequestId;
        maintenanceItem.Equipment__c = equipmentId;
        return maintenanceItem;
    }

    // Positive Testing
    @IsTest private static void testPositive(){
        Vehicle__c vehicle = createVehicle();
        insert vehicle;

        Product2 equipment = createEquipment();
        insert equipment;

        Case testCase = createMaintenanceRequest(vehicle.Id);
        insert testCase;

        Equipment_Maintenance_Item__c equipmentMaintenanceItem = createEquipmentMaintenanceItem(equipment.Id, testCase.Id);
        insert equipmentMaintenanceItem;

        Test.startTest();
        testCase.Status = 'Closed';
        update testCase;
        Test.stopTest();

        // Query the newly Auto created case from the above update and result of Trigger fired
        Case autoCreatedCase = [SELECT Id, Subject, Type, Vehicle__c, Date_Reported__c, Date_Due__c
        FROM Case WHERE Status = 'New'];

        // Query the related Equipment Maintenance Items from the Auto created Case
        Equipment_Maintenance_Item__c autoItem = [SELECT Id FROM Equipment_Maintenance_Item__c
        WHERE Maintenance_Request__c =: autoCreatedCase.Id];

        // Assertion
        List<Case> cases = [SELECT Id FROM Case];
        System.assert(cases.size() == 2);

        System.assert(autoCreatedCase != null);
        System.assertEquals(autoCreatedCase.Subject, 'Auto Routine Maintenance');
        System.assertEquals(autoCreatedCase.Type, 'Routine Maintenance');
        System.assertEquals(autoCreatedCase.Vehicle__c, vehicle.Id);
        System.assertEquals(autoCreatedCase.Date_Reported__c, System.today());
    }

    // Negative Testing
    @IsTest private static void testNegative(){
        Vehicle__c vehicle = createVehicle();
        insert vehicle;

        Product2 equipment = createEquipment();
        insert equipment;

        Case testCase = createMaintenanceRequest(vehicle.Id);
        insert testCase;

        Equipment_Maintenance_Item__c equipmentMaintenanceItem = createEquipmentMaintenanceItem(equipment.Id, testCase.Id);
        insert equipmentMaintenanceItem;

        Test.startTest();
        testCase.Status = 'Working';
        update testCase;
        Test.stopTest();

        List<Case> cases = [SELECT Id FROM Case];

        List<Equipment_Maintenance_Item__c> maintenanceItems = [SELECT Id FROM Equipment_Maintenance_Item__c];

        System.assert(cases.size() == 1);
        System.assert(maintenanceItems.size() == 1 );

    }

    // Bulk Testing
    @IsTest private static void testBulk(){
        // List to hold the item for bulkification insert
        List<Vehicle__c> vehicles = new List<Vehicle__c>();
        List<Equipment_Maintenance_Item__c> maintenanceItems = new List<Equipment_Maintenance_Item__c>();
        List<Product2> equipments = new List<Product2>();
        List<Case> cases = new List<Case>();

        for (Integer i = 0; i < 300; i++) {
            vehicles.add(new Vehicle__c(Name='My Testing Vehicle ' + i+1));
            equipments.add(new Product2(Name='My Testing Equipment '+ i+1,
                    Lifespan_Months__c=8, Maintenance_Cycle__c = i+1,
                    Replacement_Part__c=true));
        }

        insert vehicles;
        insert equipments;

        for (Integer i = 0 ; i < 300; i++) {
              cases.add(new Case(Type= 'Repair', Status='New',
                      Subject='Testing Subject '+ i+1, Vehicle__c= vehicles.get(i).Id));
        }
        insert cases;

        // System.debug('Total Cases: ' + cases.size());
        // System.debug(equipments.size());
        for (Integer i = 0; i < 300; i++) {
            maintenanceItems.add(new Equipment_Maintenance_Item__c(Maintenance_Request__c= cases.get(i).Id,
        Equipment__c= equipments.get(i).Id));
        }
        insert maintenanceItems;

        Test.startTest();
        for (Case aCase : cases) {
            aCase.Status = 'Closed';
        }
        update cases;
        Test.stopTest();

        List<Case> newAutoCases = [SELECT Id FROM Case WHERE Status = 'New'];

        List<Equipment_Maintenance_Item__c> totalEquipmentItems = [SELECT Id FROM Equipment_Maintenance_Item__c];

        // Check the count of newly auto created Cases
        System.assert(newAutoCases.size() == 300);

        // Check the total Cases and Equipment Maintenance Items
        List<Case> totalCases = [SELECT Id FROM Case];
        System.assert(totalCases.size() == 600);
        System.assert(totalEquipmentItems.size() == 600);
    }

}