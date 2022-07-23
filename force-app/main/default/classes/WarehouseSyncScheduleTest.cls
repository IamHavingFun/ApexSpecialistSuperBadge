@IsTest
public with sharing class WarehouseSyncScheduleTest {
    // implement scheduled code here
    @IsTest static void testSchedule(){
        String cronSchedule = '0 0 0 ? * * *'; // runs at 12:00 AM Every Day
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        String jobId = System.schedule('Warehouse Callout Schedule Every Day Testing',
                cronSchedule, new WarehouseSyncSchedule());
        Test.stopTest();
        CronTrigger cronTrigger = [SELECT State FROM CronTrigger WHERE Id =: jobId];
        System.assertEquals('WAITING', String.valueOf(cronTrigger.State), 'Not match');

    }
}