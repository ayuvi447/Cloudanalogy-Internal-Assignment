import { LightningElement, api } from 'lwc';

export default class KpiCard extends LightningElement {
    @api title; 
    @api value;   
    @api trend;   
    @api cardId;   
    get isTrendUp()   { return this.trend === 'up'; }
    get isTrendDown() { return this.trend === 'down'; }

    handleClick() {
        this.dispatchEvent(new CustomEvent('cardselect', {
            detail: { cardId: this.cardId }
        }));
    }
    // 
}