#!/bin/zsh

set -u

cat <<'GUIDE'
Limite de Carga no macOS

Recomendacao por uso:
  80%  mesa quase o dia todo, prioridade preservar
  85%  mesa + alguma mobilidade curta
  90%  rotina mista com margem confortavel
  100% viagem, dia longo longe da tomada, emergencia

Como ajustar:
  1. Abra Ajustes do Sistema.
  2. Va em Bateria.
  3. Clique no botao de informacao ao lado de Carregamento.
  4. Ative Carregamento Otimizado.
  5. Defina Limite de Carga entre 80% e 100%.

Observacao:
  Em macOS Tahoe 26.4+ com Apple Silicon, a Apple documenta Limite de Carga nativo.
  O macOS pode carregar a 100% ocasionalmente para manter a estimativa de carga precisa.
GUIDE

if [[ "${1:-}" == "--open" ]]; then
  open "x-apple.systempreferences:com.apple.Battery-Settings.extension" >/dev/null 2>&1 || open -b com.apple.systempreferences
fi
