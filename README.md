# Mac Battery Ops

Observação de bateria e planejamento explícito de Modo Pouca Energia. Python
3.10+; adaptador de hardware para macOS. O domínio não depende do sistema.

```sh
python3 -m venv .venv
.venv/bin/python -m pip install -e .
.venv/bin/mac-battery-ops status
.venv/bin/mac-battery-ops low-power on --scope battery
# Para aplicar a mudança deliberadamente, acrescente --apply.
.venv/bin/python -m unittest discover -s tests -v
```

O comando de mudança só mostra um plano por padrão. A aplicação não eleva
privilégios automaticamente. A leitura ausente/inválida não vira uma bateria
com 100%. Os testes usam portas falsas e não alteram energia ou serviços.

`legacy/` preserva os scripts anteriores para comparação. Instalação de logger,
alterações de UI e parada de aplicativos são ações manuais e não fazem parte
dos testes. A automação antiga exige `MAC_BATTERY_ALLOW_CHANGES=1` para modos
que modificam o sistema. Logs e dados da bateria ficam privados.

Veja [arquitetura](docs/architecture.md), [TDD](docs/tdd.md) e [segurança](SECURITY.md).
