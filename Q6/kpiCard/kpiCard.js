import { LightningElement, api } from 'lwc';

export default class KpiCard extends LightningElement {

    @api title;
    @api value;
    @api trend;
    @api cardId;

    handleClick(){

        this.dispatchEvent(
            new CustomEvent(
                'cardclick',
                {
                    detail:{
                        cardId:this.cardId
                    }
                }
            )
        );
    }

    get trendClass() {
    return this.trend.startsWith('+')
        ? 'positive'
        : 'negative';
}
}
