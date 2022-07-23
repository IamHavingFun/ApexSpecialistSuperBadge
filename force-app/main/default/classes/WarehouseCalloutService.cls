public with sharing class WarehouseCalloutService implements Queueable, Database.AllowsCallouts {

    private static final String WAREHOUSE_URL = 'https://th-superbadge-apex.herokuapp.com/equipment';

    public void execute(QueueableContext queueableContext) {
        // Implement an Apex class (called WarehouseCalloutService) that implements the queueable interface
        // and makes a callout to the external service used for warehouse inventory management.
        Http http = new Http();

        HttpRequest request = new HttpRequest();
        request.setEndpoint(WAREHOUSE_URL);
        request.setMethod('GET');

        // set response
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            List<Object> jsonResponse = (List<Object>)JSON.deserializeUntyped(response.getBody());
            List<Product2> productList = new List<Product2>();
            for (Object obj : jsonResponse) {
                Map<String, Object> jsonMap = (Map<String, Object>) obj;
                Product2 product2 = new Product2();
                product2.Name = (String) jsonMap.get('name');
                product2.Replacement_Part__c = (Boolean)jsonMap.get('replacement');
                product2.Current_Inventory__c = (Double) jsonMap.get('quantity');
                product2.Maintenance_Cycle__c = (Integer) jsonMap.get('maintenanceperiod');
                product2.Lifespan_Months__c = (Integer) jsonMap.get('lifespan');
                product2.Cost__c = (Decimal) jsonMap.get('cost');
                product2.Warehouse_SKU__c = (String) jsonMap.get('sku'); // this is external ID
                productList.add(product2);
            }
            if (productList.size() > 0) {
                upsert productList Warehouse_SKU__c;
            }

        }
    }
}