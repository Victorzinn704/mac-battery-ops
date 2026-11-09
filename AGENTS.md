# Fluxo de trabalho

- Antes de editar, use uma branch `<tipo>/<descricao-em-kebab-case>` por tarefa.
- Não faça commit/push direto em main/master. Não abra PR para main nem faça merge sem solicitação explícita.
- Não crie develop/staging apenas por conveniência. A branch inicial desta entrega é chore/bootstrap.
- Escreva um teste de comportamento que falhe antes de implementar uma alteração funcional; verifique a causa da falha, implemente e refatore mantendo os testes passando.
- Não execute scripts que alterem bateria, áudio, serviços ou rede durante testes; injete adaptadores e use fixtures temporárias.
- Execute o comando de validação do README e Gitleaks antes de enviar. Nunca versione mídias, dados pessoais, logs ou credenciais.
