import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class FlowModalContent extends LightningModal {
    @api content;

    stageOptions = [
        { label: 'Prospecting', value: 'Prospecting' },
        { label: 'Qualification', value: 'Qualification' },
        { label: 'Needs Analysis', value: 'Needs Analysis' },
        { label: 'Value Proposition', value: 'Value Proposition' },
        { label: 'Id. Decision Makers', value: 'Id. Decision Makers' },
        { label: 'Perception Analysis', value: 'Perception Analysis' },
        { label: 'Proposal/Price Quote', value: 'Proposal/Price Quote' },
        { label: 'Negotiation/Review', value: 'Negotiation/Review' },
        { label: 'Closed Won', value: 'Closed Won' },
        { label: 'Closed Lost', value: 'Closed Lost' }
    ];

    selectedStage;

    get isSaveDisabled() {
        return !this.selectedStage;
    }

    handleStageChange(event) {
        this.selectedStage = event.detail.value;
    }

    handleClose() {
        this.close();
    }

    handleSave() {
        this.close(this.selectedStage);
    }
}