#!/bin/zsh

set -u

SCRIPT_DIR="${0:A:h}"
. "$SCRIPT_DIR/lib/battery_common.sh"

percent="$(battery_percent)"
state="$(battery_state)"
source="$(power_source)"
cycles="$(sp_value "Cycle Count")"
condition="$(sp_value "Condition")"
max_capacity="$(sp_value "Maximum Capacity" | tr -d '%')"
temp_c="$(battery_temp_c)"
low_power_battery="$(low_power_value battery)"

echo "Battery Ops - recomendacao"
echo
print_kv "Power source" "$source"
print_kv "Battery" "${percent}% / ${state}"
print_kv "Health" "${condition}, ${max_capacity}% max, ${cycles} cycles"
print_kv "Battery temp" "${temp_c} C"
echo

if [[ "$condition" != "Normal" ]]; then
  echo "- Alerta: a condicao nao esta Normal. Rode o status completo e considere suporte Apple se persistir."
fi

if [[ -n "$max_capacity" && "$max_capacity" -le 80 ]]; then
  echo "- Alerta: capacidade em ${max_capacity}%. Planeje avaliacao de bateria se a autonomia estiver ruim."
elif [[ -n "$max_capacity" && "$max_capacity" -le 90 ]]; then
  echo "- Atencao: capacidade em ${max_capacity}%. Vale acompanhar mensalmente."
fi

if [[ -n "$cycles" && "$cycles" -ge 1000 ]]; then
  echo "- Ciclos: no limite de referencia do modelo. Troca passa a fazer sentido se a autonomia incomodar."
elif [[ -n "$cycles" && "$cycles" -ge 700 ]]; then
  echo "- Ciclos: fase amarela. Continue preservando calor e uso em 100% prolongado."
fi

temp_int="${temp_c%.*}"
if [[ -n "$temp_int" && "$temp_int" -ge 35 ]]; then
  echo "- Temperatura: bateria quente. Evite carga pesada carregando; melhore ventilacao."
fi

if [[ "$source" == "AC Power" ]]; then
  if [[ -n "$percent" && "$percent" -ge 80 ]]; then
    echo "- Tomada: bom para mesa. Configure Limite de Carga em 80-90% se ficar horas conectado."
  else
    echo "- Tomada: pode carregar agora. Para rotina longa, use Limite de Carga em 80-90%."
  fi
  echo "- Use 100% apenas antes de sair, viagem ou dia longo longe da tomada."
else
  if [[ -n "$percent" && "$percent" -le 20 ]]; then
    echo "- Bateria baixa: conecte na tomada quando puder e ative Modo Pouca Energia."
  elif [[ -n "$percent" && "$percent" -le 40 ]]; then
    echo "- Bateria moderada: se o dia ainda for longo, ative Modo Pouca Energia ou carregue."
  elif [[ -n "$percent" && "$percent" -ge 80 ]]; then
    echo "- Bateria alta: se for ficar na mesa, pode conectar com Limite de Carga ativo."
  else
    echo "- Bateria em faixa saudavel para uso leve. Sem acao urgente."
  fi
fi

if [[ "$source" == "Battery Power" && "$low_power_battery" == "0" && -n "$percent" && "$percent" -le 40 ]]; then
  echo "- Sugestao: rode battery_ops/bin/battery_low_power.sh on battery."
fi
