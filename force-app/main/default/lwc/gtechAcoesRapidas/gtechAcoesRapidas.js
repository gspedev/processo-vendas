import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

const ACOES = [
    { objeto: 'Lead', icone: 'standard:lead', titulo: 'Criar Lead', descricao: 'Novo potencial cliente' },
    { objeto: 'Account', icone: 'standard:account', titulo: 'Criar Conta', descricao: 'Nova empresa (CNPJ)' },
    { objeto: 'Contact', icone: 'standard:contact', titulo: 'Criar Contato', descricao: 'Nova pessoa na conta' },
    {
        objeto: 'Opportunity',
        icone: 'standard:opportunity',
        titulo: 'Nova Oportunidade',
        descricao: 'Novo negócio no funil'
    }
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
