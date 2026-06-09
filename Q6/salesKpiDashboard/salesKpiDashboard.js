import { LightningElement, wire, track } from 'lwc';

import getKpiSummary
from '@salesforce/apex/SalesKpiController.getKpiSummary';

import {
    publish,
    subscribe,
    MessageContext
}
from 'lightning/messageService';

import REGION_CHANNEL
from '@salesforce/messageChannel/RegionFilter__c';

export default class SalesKpiDashboard extends LightningElement {

    @track openPipeline;
    @track wonRevenue;
    @track avgDealSize;
    @track winRate;

    selectedRegion = 'North';
    selectedCard;

    intervalId;
    subscription;

    @wire(MessageContext)
    messageContext;

    regionOptions = [
        { label: 'North', value: 'North' },
        { label: 'South', value: 'South' },
        { label: 'East', value: 'East' },
        { label: 'West', value: 'West' }
    ];

    connectedCallback() {

        this.loadData();

        this.subscribeChannel();

        this.intervalId = setInterval(() => {
            this.loadData();
        }, 30000);
    }

    disconnectedCallback() {

        if(this.intervalId){
            clearInterval(this.intervalId);
        }
    }

    subscribeChannel() {

        if(this.subscription){
            return;
        }

        this.subscription = subscribe(
            this.messageContext,
            REGION_CHANNEL,
            (message) => {
                this.selectedRegion = message.region;
                this.loadData();
            }
        );
    }

    async loadData() {

        try {

            const result =
                await getKpiSummary({
                    region: this.selectedRegion
                });

            this.openPipeline = result.openPipeline;
            this.wonRevenue = result.wonRevenue;
            this.avgDealSize = result.avgDealSize;
            this.winRate = result.winRate;

        } catch(error){
            console.error(error);
        }
    }

    handleRegionChange(event){

        this.selectedRegion = event.detail.value;

        publish(
            this.messageContext,
            REGION_CHANNEL,
            {
                region: this.selectedRegion
            }
        );

        this.loadData();
    }

    handleCardClick(event){

        this.selectedCard =
            event.detail.cardId;
    }
}