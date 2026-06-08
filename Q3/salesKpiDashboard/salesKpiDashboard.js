import { LightningElement, wire, track } from 'lwc';
import { publish, subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import REGION_FILTER_CHANNEL from '@salesforce/messageChannel/RegionFilter__c';
import getKpiSummary from '@salesforce/apex/KpiController.getKpiSummary';
import getTopOpportunities from '@salesforce/apex/KpiController.getTopOpportunities';

export default class SalesKpiDashboard extends LightningElement {

    // ─── State ───────────────────────────────────────────
    @track selectedRegion = 'All';
    @track kpiCards = [];
    @track isLoading = false;
    @track showDetail = false;
    @track selectedCardId = '';
    @track topOpportunities = [];
    @track isDetailLoading = false;

    _subscription = null;  // LMS subscription store
    _interval = null;      // setInterval reference

    @wire(MessageContext)
    messageContext;
    regionOptions = [
        { label: 'All Regions', value: 'All' },
        { label: 'North',       value: 'North' },
        { label: 'South',       value: 'South' },
        { label: 'East',        value: 'East' },
        { label: 'West',        value: 'West' }
    ];
    oppColumns = [
        { label: 'Opportunity Name', fieldName: 'Name' },
        { label: 'Account',          fieldName: 'AccountName' },  // flatten karenge
        { label: 'Amount',           fieldName: 'Amount', type: 'currency' },
        { label: 'Stage',            fieldName: 'StageName' },
        { label: 'Close Date',       fieldName: 'CloseDate', type: 'date' }
    ];



    connectedCallback() {
        // LMS subscribe — koi bhi component region change karega toh sun'te hain
        this._subscription = subscribe(
            this.messageContext,
            REGION_FILTER_CHANNEL,
            (message) => this.handleRegionMessage(message)
        );

        // Pehli baar data load karo
        this.loadKpiData();

        // Har 30 second mein refresh
        this._interval = setInterval(() => {
            this.loadKpiData();
        }, 30000);
    }

    disconnectedCallback() {
        // Memory leak rokne ke liye dono clear karo
        unsubscribe(this._subscription);
        clearInterval(this._interval);
    }

    // ─── Region Change Handler ────────────────────────────

    handleRegionChange(event) {
        this.selectedRegion = event.detail.value;

        // LMS publish — saare subscribers ko batao
        publish(this.messageContext, REGION_FILTER_CHANNEL, {
            region: this.selectedRegion
        });

        // Apna data bhi update karo
        this.loadKpiData();
    }

    handleRegionMessage(message) {
        // Agar koi aur component ne publish kiya (same page pe)
        if (message.region !== this.selectedRegion) {
            this.selectedRegion = message.region;
            this.loadKpiData();
        }
    }

    // ─── KPI Data Load ────────────────────────────────────

    loadKpiData() {
        this.isLoading = true;
        getKpiSummary({ region: this.selectedRegion })
            .then(data => {
                this.kpiCards = this.buildKpiCards(data);
                this.isLoading = false;
            })
            .catch(error => {
                console.error('KPI load error:', error);
                this.isLoading = false;
            });
        
        
    }

    buildKpiCards(data) {
        // Apex se aaya raw data → card format mein convert
        return [
            {
                cardId: 'openPipeline',
                title:  'Open Pipeline',
                value:  '$' + this.formatNumber(data.openPipeline),
                trend:  'up'
            },
            {
                cardId: 'wonRevenue',
                title:  'Won Revenue',
                value:  '$' + this.formatNumber(data.wonRevenue),
                trend:  'up'
            },
            {
                cardId: 'avgDealSize',
                title:  'Avg Deal Size',
                value:  '$' + this.formatNumber(data.avgDealSize),
                trend:  'flat'
            },
            {
                cardId: 'winRate',
                title:  'Win Rate',
                value:  data.winRate + '%',
                trend:  data.winRate > 50 ? 'up' : 'down'
            }
        ];
    }

    handleCardSelect(event) {   
        this.selectedCardId = event.detail.cardId;
        this.showDetail = true;
        this.isDetailLoading = true;

        getTopOpportunities({
            region: this.selectedRegion,
            kpiType: this.selectedCardId
        })
        .then(opps => {
            // Account.Name flatten karna zaroori hai datatable ke liye
            this.topOpportunities = opps.map(o => ({
                ...o,
                AccountName: o.Account?.Name
            }));
            this.isDetailLoading = false;
            console.log('Top opportunities loaded:', this.topOpportunities);
            console.log('Top opportunities loaded successfully');
            
        })
        .catch(err => {
            console.error('Detail load error:', err);
            this.isDetailLoading = false;
        });
    }

    // ─── Getters ──────────────────────────────────────────

    get detailTitle() {
        return 'Top 5 Opportunities — ' + this.selectedCardId;
    }

    get hasOpportunities() {
        return this.topOpportunities && this.topOpportunities.length > 0;
    }

    // ─── Utility ──────────────────────────────────────────

    formatNumber(num) {
        if (!num) return '0';
        return Number(num).toLocaleString('en-IN');
    }
}