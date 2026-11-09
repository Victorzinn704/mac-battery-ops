# Ciclo verificado

1. RED: os contratos de comportamento foram escritos e executados antes dos
   módulos de implementação; a execução falhou pela ausência esperada do pacote.
2. GREEN: domínio, portas e casos de uso foram implementados; os seis testes
   iniciais de cada projeto passaram usando adaptadores falsos/temporários.
3. REFACTOR: empacotamento, CLI, segurança e compatibilidade foram revisados
   mantendo a suíte passando. Testes adicionais de regressão têm seus próprios
   ciclos RED/GREEN quando encontram uma lacuna de comportamento.

Os commits `test: define use case contracts before implementation` e
`feat: implement use cases behind ports and adapters` registram os checkpoints.
Os resultados detalhados estão no relatório privado da auditoria. Não se
atribui TDD retroativamente aos scripts originais.
