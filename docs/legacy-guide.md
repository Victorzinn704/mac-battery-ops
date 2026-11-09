> Notas históricas do conjunto original. Instruções de hardware e recomendações não foram revalidadas nesta publicação.

# Battery Ops

Scripts locais para acompanhar consumo e preservar a bateria do MacBook.

## Comandos principais

```bash
battery_ops/bin/battery_status.sh
battery_ops/bin/battery_advice.sh
battery_ops/bin/battery_log.sh
```

## Modo Pouca Energia

Ver status:

```bash
battery_ops/bin/battery_low_power.sh status
```

Ativar so quando estiver na bateria:

```bash
battery_ops/bin/battery_low_power.sh on battery
```

Desativar so quando estiver na bateria:

```bash
battery_ops/bin/battery_low_power.sh off battery
```

Alterar configuracoes de energia via `pmset` pode pedir senha de administrador.

## Log automatico opcional

Instalar log horario:

```bash
battery_ops/bin/install_hourly_logger.sh
```

Remover:

```bash
battery_ops/bin/uninstall_hourly_logger.sh
```

Os logs ficam em `battery_ops/logs/battery_log.csv`.

## Limite de carga

O macOS nao oferece um comando oficial documentado para configurar o Limite de Carga por terminal. Para ajustar:

1. Abra Ajustes do Sistema.
2. Va em Bateria.
3. Clique no botao de informacao ao lado de Carregamento.
4. Defina Limite de Carga entre 80% e 100%.

Para rotina de mesa, comece com 80% ou 85%. Use 100% quando precisar sair com autonomia maxima.

Guia rapido:

```bash
battery_ops/bin/charge_limit_guide.sh
```

Abrir Ajustes do Sistema:

```bash
battery_ops/bin/charge_limit_guide.sh --open
```
