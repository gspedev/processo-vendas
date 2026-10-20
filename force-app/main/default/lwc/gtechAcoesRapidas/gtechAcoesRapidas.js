import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

const ACOES = [
    { objeto: 'Lead', icone: 'standard:lead', titulo: 'Criar Lead', descricao: 'Novo potencial cliente' },
    { objeto: 'Account', icone: 'standard:account', titulo: 'Criar Conta', descricao: 'Nova empresa (CNPJ)' }
];

export default class GtechAcoesRapidas extends NavigationMixin(LightningElement) {
    acoes = ACOES.map((acao) => ({ ...acao, ariaLabel: `${acao.titulo}: ${acao.descricao}` }));

    handleClick(event) {
        const objectApiName = event.currentTarget.dataset.objeto;
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName, actionName: 'new' }
        });
    }
}
