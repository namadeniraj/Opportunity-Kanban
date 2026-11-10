/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class OpportunityControllerTest {

    @isTest static void testGetOpportunities() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpportunity;

        // Call the method to be tested
        List<Opportunity> opportunities = OpportunityController.getOpportunities('Prospecting');

        // Verify the results
        System.assertEquals(1, opportunities.size(), 'Expected one opportunity to be returned.');
        System.assertEquals(testOpportunity.Id, opportunities[0].Id, 'The returned opportunity ID does not match the expected ID.');
    }

    @isTest static void testGetOpportunitiesWithMultipleStages() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpportunity1 = new Opportunity(
            Name = 'Test Opportunity 1',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpportunity1;

        Opportunity testOpportunity2 = new Opportunity(
            Name = 'Test Opportunity 2',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpportunity2;

        // Call the method to be tested
        List<Opportunity> opportunities = OpportunityController.getOpportunitiesWithMultipleStages('Prospecting', 'Qualification');

        // Verify the results
        System.assertEquals(2, opportunities.size(), 'Expected two opportunities to be returned.');
    }

    @isTest static void testDeleteOpportunity() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpportunity;

        // Call the method to be tested
        Test.startTest();
        OpportunityController.deleteOpportunity(testOpportunity.Id);
        Test.stopTest();
    }

    @isTest static void testUpdateOpportunityStage() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity testOpportunity = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        Opportunity testOpportunity2 = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        oppList.add(testOpportunity);
        oppList.add(testOpportunity2);
        insert oppList;

        // Call the method to be tested
        Test.startTest();
        String resultMessage = OpportunityController.updateOpportunityStage(testOpportunity.Id, 'Qualification');
        String resultMessage2 = OpportunityController.updateOpportunityStage(testOpportunity2.Id, 'Qualification');
        Test.stopTest();

        // Verify the results
        Opportunity updatedOpportunity = [SELECT Id, StageName FROM Opportunity WHERE Id = :testOpportunity.Id LIMIT 1];
        System.assertEquals('Qualification', updatedOpportunity.StageName, 'The opportunity stage should have been updated to Qualification.');
        System.assertEquals('Opportunity updated to Stage: Qualification', resultMessage, 'The result message does not match the expected message.');
    }
}