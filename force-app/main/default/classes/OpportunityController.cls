public without sharing class OpportunityController {

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunities(String stageName){
        List<Opportunity> oppList = [SELECT Id, Name, StageName, Amount, OwnerId, Owner.Name, Type 
                                     FROM Opportunity
                                     WHERE StageName = :stageName
                                     WITH USER_MODE];
        return oppList;
    }

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunitiesWithMultipleStages(String stageName, String stageName2){
        List<Opportunity> oppList = [SELECT Id, Name, StageName, Amount, OwnerId, Owner.Name, Type 
                                     FROM Opportunity
                                     WHERE StageName = :stageName OR StageName = :stageName2
                                     WITH USER_MODE];
        return oppList;
    }

    @AuraEnabled
    public static void deleteOpportunity(Id oppId) {
            Opportunity oppToDelete = [SELECT Id FROM Opportunity WHERE Id = :oppId LIMIT 1];
            Database.delete(oppToDelete);
    }

    @AuraEnabled
    public static String updateOpportunityStage(Id oppId, String newStage) {
        String message;
        Opportunity oppToUpdate = [SELECT Id, StageName FROM Opportunity WHERE Id = :oppId LIMIT 1];
        if(oppToUpdate.StageName != newStage) {
            oppToUpdate.StageName = newStage;
            Database.update(oppToUpdate);
            message = 'Opportunity updated to Stage: ' + newStage;
        }
        else{
            message = 'Opportunity is already in Stage: ' + newStage;
        }
        return message;
    }

}
