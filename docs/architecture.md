# Portas e adaptadores

`domain.py` valida leituras e representa mudanças de energia. `application.py`
coordena os casos de uso e depende dos contratos em `ports.py`. `adapters.py`
é o único módulo que chama pmset; recebe o executor por injeção. `cli.py` monta
o serviço e converte argumentos em operações. Nenhuma chamada usa shell=True.

O legado foi preservado separadamente e não é instalado como daemon. Os
limiares e conselhos históricos do legado não são diagnósticos de hardware.
