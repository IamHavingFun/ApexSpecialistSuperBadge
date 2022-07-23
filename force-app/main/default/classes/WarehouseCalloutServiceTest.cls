@IsTest
private class WarehouseCalloutServiceTest {
    // implement your mock callout test here
    @IsTest
    static void testWarehouseCallout(){
        Test.setMock(HttpCalloutMock.class, new WarehouseCalloutServiceMock());
        Test.startTest();
        Id jobId = System.enqueueJob(new WarehouseCalloutService());
        Test.stopTest();

        List<Product2> product2s = [SELECT Warehouse_SKU__c FROM Product2];
        System.debug(product2s.size());

        for (Product2 product2 : product2s) {
            System.debug(product2.Warehouse_SKU__c);
        }

        System.assertNotEquals(null, jobId);
        System.assertEquals(3, product2s.size());
        System.assertEquals('100003', product2s.get(0).Warehouse_SKU__c);
    }

}