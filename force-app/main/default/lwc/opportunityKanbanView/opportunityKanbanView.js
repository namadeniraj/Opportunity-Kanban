import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import FlowModalContent from 'c/flowModalContent';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getOpportunities from '@salesforce/apex/OpportunityController.getOpportunities';
import getOpportunitiesWithMultipleStages from '@salesforce/apex/OpportunityController.getOpportunitiesWithMultipleStages';
import deleteOpportunity from '@salesforce/apex/OpportunityController.deleteOpportunity';
import updateOpportunityStage from '@salesforce/apex/OpportunityController.updateOpportunityStage';

export default class OpportunityKanbanView extends NavigationMixin(LightningElement) {

    isLoading;
    selectedStage;
    updatingOpportunityId;

    async refreshData() {
        await refreshApex(this.prospectingopps);
        await refreshApex(this.qualificationNeedAnalysisopps);
        await refreshApex(this.valuePropDecisionMakersopps);
        await refreshApex(this.perceptionAnalysisProposalopps);
        await refreshApex(this.negotiationReviewopps);
        await refreshApex(this.closedWonLostopps);
    }

    @wire(getOpportunities, { stageName: 'Prospecting' }) prospectingopps;
    @wire(getOpportunitiesWithMultipleStages, { stageName: 'Qualification', stageName2: 'Needs Analysis' }) qualificationNeedAnalysisopps;
    @wire(getOpportunitiesWithMultipleStages, { stageName: 'Value Proposition', stageName2: 'Id. Decision Makers' }) valuePropDecisionMakersopps;
    @wire(getOpportunitiesWithMultipleStages, { stageName: 'Perception Analysis', stageName2: 'Proposal/Price Quote' }) perceptionAnalysisProposalopps;
    @wire(getOpportunities, { stageName: 'Negotiation/Review' }) negotiationReviewopps;
    @wire(getOpportunitiesWithMultipleStages, { stageName: 'Closed Won', stageName2: 'Closed Lost' }) closedWonLostopps;

    get prospectingCards() {
        return this.cardsWithSpinner(this.prospectingopps?.data);
    }

    get qualificationNeedAnalysisCards() {
        return this.cardsWithSpinner(this.qualificationNeedAnalysisopps?.data);
    }

    get valuePropDecisionMakersCards() {
        return this.cardsWithSpinner(this.valuePropDecisionMakersopps?.data);
    }

    get perceptionAnalysisProposalCards() {
        return this.cardsWithSpinner(this.perceptionAnalysisProposalopps?.data);
    }

    get negotiationReviewCards() {
        return this.cardsWithSpinner(this.negotiationReviewopps?.data);
    }

    get closedWonLostCards() {
        return this.cardsWithSpinner(this.closedWonLostopps?.data);
    }

    cardsWithSpinner(opportunities = []) {
        return opportunities.map(opportunity => ({
            ...opportunity,
            isUpdating: opportunity.Id === this.updatingOpportunityId
        }));
    }

    handleCardClick(event) {
        const cardRecordId = event.currentTarget.dataset.id;
        this.redirectToRecordPage(cardRecordId);
    }

    async handleActionSelect(event) {
        const selectedAction = event.detail.value;
        const cardRecordId = event.currentTarget.dataset.id;

        if (selectedAction === 'edit') {
            this.redirectToEditRecordPage(cardRecordId);
            return;
        }

        let selectedStage;
        if (selectedAction === 'changestage') {
            selectedStage = await this.openModal();
            if (!selectedStage) {
                return;
            }
        }

        this.updatingOpportunityId = cardRecordId;
        try {
            if (selectedAction === 'delete') {
                await deleteOpportunity({ oppId: cardRecordId });
                await this.refreshData();
                this.showToast('Opportunity Deleted', 'The opportunity has been deleted.', 'success');
            } else if (selectedAction === 'changestage') {
                this.selectedStage = selectedStage;
                const message = await updateOpportunityStage({ oppId: cardRecordId, newStage: selectedStage });
                await this.refreshData();
                this.showToast('Opportunity Updated', message, 'success');
            }
        } catch (error) {
            this.showToast(
                'Opportunity Not Updated',
                error?.body?.message || error?.message || 'The requested action failed.',
                'error'
            );
        } finally {
            this.updatingOpportunityId = undefined;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    async handleGlobalAction(event) {
        this.refreshData();
    }

    async openModal() {
        const result = await FlowModalContent.open({
            // Pass any parameters/content to the modal here
            size: 'small', // Options: small, medium, large
            description: 'A modal pop-up box resembling screen flow behavior',
            content: 'Initial Data',
        });

        return result;
    }


    redirectToRecordPage(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
    }

    redirectToEditRecordPage(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Opportunity',
                actionName: 'edit'
            }
        });
    }
}