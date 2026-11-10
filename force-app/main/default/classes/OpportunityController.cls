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

    // @AuraEnabled(cacheable=true)
    // public static Map<Opportunity, String> getAllApprovalRecords(){
    //     Id userId = UserInfo.getUserId();
    //     Map<Opportunity, String> approvalStatusMap = new Map<Opportunity, String>();
    //     List<Id> oppIds = new List<Id>();
    //     List<ProcessInstanceStep> processInstancesStep = [SELECT Id, StepStatus, ProcessInstance.TargetObjectId, ActorId FROM ProcessInstanceStep  WHERE ActorId = :userId];

    //     if(!processInstancesStep.isEmpty()){
    //         for(ProcessInstanceStep ps : processInstancesStep){
    //             if(ps.ActorId != null){
    //                 oppIds.add(ps.ProcessInstance.TargetObjectId);
    //             }
    //         }
    //     }

    //     List<Opportunity> oppList = [SELECT Id, Name FROM Opportunity WHERE Id IN :oppIds];
    //     for(Opportunity opp : oppList){
    //         for(ProcessInstanceStep ps : processInstancesStep){
    //             approvalStatusMap.put(opp, ps.StepStatus);
    //         }
    //     }

    //     // System.debug('approvalStatusMap ====> ' + approvalStatusMap);

    //     return approvalStatusMap;
    // }

    @AuraEnabled(cacheable=true)
    public static List<ApprovalRequest> getAllPendingApprovalRecords(){
        Id userId = UserInfo.getUserId();
        List<ApprovalRequest> result = new List<ApprovalRequest>();
        List<ProcessInstanceWorkitem> workItems = [SELECT Id, ActorId, 
                                                     ProcessInstance.Status, ProcessInstance.TargetObjectId 
                                                     FROM ProcessInstanceWorkitem 
                                                     WHERE ActorId = :userId];
        Set<Id> oppIds = new Set<Id>();
        for(ProcessInstanceWorkitem workItem : workItems){
            Id targetId = workItem.ProcessInstance.TargetObjectId;
            if(targetId != null && targetId.getSobjectType() == Opportunity.getSObjectType()){
                oppIds.add(workItem.ProcessInstance.TargetObjectId);
            }
        }

        Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>([
            SELECT Id, Name
            FROM Opportunity
            WHERE Id IN :oppIds
        ]);

        for(ProcessInstanceWorkitem workItem : workItems){
            Id targetId = workItem.ProcessInstance.TargetObjectId;
            if(opportunities.containsKey(targetId)){
                Opportunity opp = opportunities.get(targetId);
                result.add(New ApprovalRequest(opp.id, opp.Name, String.valueOf(workItem.ProcessInstance.Status)));
            }
        }
        
        System.debug(result);
        return result;

    }

    @AuraEnabled(cacheable=true)
    public static String getAllProcessInstance(){
        List<ProcessInstanceStep> allOppHistory = new List<ProcessInstanceStep>();

        List<Id> processInstanceIds = new List<Id>();
        List<Id> oppIds = new List<Id>();

        List<ApprovalHistoryWrapper> result = new List<ApprovalHistoryWrapper>();

        String response;

        List<ProcessInstance> processInstance = [SELECT Id, TargetObjectId, Status FROM ProcessInstance];

        for(ProcessInstance singleInstance : processInstance){
            if(singleInstance.TargetObjectId != null && singleInstance.TargetObjectId.getSobjectType() == Opportunity.getSobjectType()){
                processInstanceIds.add(singleInstance.Id);
                oppIds.add(singleInstance.TargetObjectId);
            }
        }

        allOppHistory = [SELECT Id, StepStatus, CreatedDate, Actor.Name,
                         ProcessInstance.TargetObjectId, ProcessInstance.Status
                         FROM ProcessInstanceStep where ProcessInstanceId IN :processInstanceIds
                         AND ProcessInstance.TargetObjectId IN :oppIds];
        
        List <Opportunity> opportunities = [SELECT Id, Name, CloseDate, StageName, Amount FROM Opportunity WHERE Id IN :oppIds];

        for(Opportunity opp : opportunities){
            List<ProcessInstanceStepWrapper> steps = new List<ProcessInstanceStepWrapper>();
            String approvalStatus;
            for(ProcessInstanceStep process : allOppHistory){
                if(opp.Id == process.ProcessInstance.TargetObjectId){
                    String actor = process.Actor.Name;
                    String stepStatus = process.StepStatus;
                    Datetime createDate = process.CreatedDate;
                    ProcessInstanceStepWrapper pStep = new ProcessInstanceStepWrapper(actor, stepStatus, createDate);
                    steps.add(pStep);
                    approvalStatus = process.ProcessInstance.Status;
                }
            }
            ApprovalHistoryWrapper oppHistory = new ApprovalHistoryWrapper(opp.Id, opp.Name, opp.CloseDate, opp.Amount, opp.StageName, approvalStatus, steps);
            result.add(oppHistory);
        }

        response = JSON.serialize(result);

        return response;

    }

    public class ApprovalHistoryWrapper{
        @AuraEnabled public Id opportunityId { get; set; }
        @AuraEnabled public String opportunityName { get; set; }
        @AuraEnabled public Date closeDate{get; set;}
        @AuraEnabled public Decimal amount{get; set;}
        @AuraEnabled public String stage{get; set;}
        @AuraEnabled public String approvalStatus{get; set;}
        @AuraEnabled public List<ProcessInstanceStepWrapper> ps { get; set; }
        public ApprovalHistoryWrapper(Id opportunityId, String opportunityName, Date closeDate, Decimal amount, String stage, String approvalStatus, List<ProcessInstanceStepWrapper> psList){
            this.opportunityId = opportunityId;
            this.opportunityName = opportunityName;
            this.closeDate = closeDate;
            this.amount = amount;
            this.stage = stage;
            this.approvalStatus = approvalStatus;
            this.ps = psList;
        }
    }

    public class ProcessInstanceStepWrapper{
        @AuraEnabled public String actorId {get; set;}
        @AuraEnabled public String stepStatus {get; set;}
        @AuraEnabled public DateTime createdDate {get; set;}
        public ProcessInstanceStepWrapper(String actorId, String stepStatus, DateTime createdDate){
            this.actorId = actorId;
            this.stepStatus = stepStatus;
            this.createdDate = createdDate;
        }
    }


    public class ApprovalRequest {
        @AuraEnabled public Id opportunityId { get; set; }
        @AuraEnabled public String opportunityName { get; set; }
        @AuraEnabled public String approvalStatus { get; set; }

        public ApprovalRequest(Id opportunityId, String opportunityName, String approvalStatus){
            this.opportunityId = opportunityId;
            this.opportunityName = opportunityName;
            this.approvalStatus = approvalStatus;
        }

    }

}