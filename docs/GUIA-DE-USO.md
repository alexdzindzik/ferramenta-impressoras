# Guia de uso

## Abrindo a ferramenta

1. Coloque `ferramenta_impressoras.ps1` e `Abrir_Ferramenta_Impressoras.bat` na mesma pasta (pendrive, pasta de rede ou na máquina do usuário via acesso remoto).
2. Dê duplo clique no **`.bat`**. Ele abre o script sem o bloqueio de política de execução e a ferramenta pede elevação (UAC).
3. A primeira linha da área de saída informa se a ferramenta está rodando **como administrador** ou não.

## Campos

| Campo | Uso |
|---|---|
| **Nome / filtro** | Nome da impressora (para DNS e para adicionar) ou parte do nome/modelo (para remover) |
| **IP** | IP da impressora (para testar portas e adicionar) |
| **Final do MAC** | Últimos 3 bytes do MAC, em qualquer formato: `A1B2C3`, `A1:B2:C3` ou `a1-b2-c3` |

## Botões

### Listar impressoras
Mostra três blocos:
- **Impressoras**: nome, driver, porta, se é de rede e se é a padrão.
- **Portas TCP/IP**: nome da porta e o **IP** da impressora — o jeito mais rápido de descobrir o IP numa máquina onde ela já funciona.
- **Drivers** instalados.

### Achar IP (DNS)
Resolve o **Nome / filtro** no DNS. Só funciona dentro da rede onde a impressora está cadastrada. Fora dela, a ferramenta avisa que o nome não foi encontrado.

### Achar IP (MAC/ARP)
Procura o **Final do MAC** na tabela ARP da máquina.

> 💡 Impressoras HP costumam mostrar os 3 últimos bytes do MAC no próprio nome do dispositivo, por exemplo `HP LaserJet MFP [A1B2C3]`.

Se não encontrar, a máquina ainda não conversou com a impressora. Pingue a faixa da rede e tente de novo.

### Testar portas do IP
Testa as portas da impressora a partir da máquina atual:
- **631 (IPP)**: necessária para o botão **Adicionar via IP**.
- **9100 (RAW)**: impressão direta, usada pelos drivers dos fabricantes.
- **80 (HTTP)**: painel web da impressora.

Se todas estiverem fechadas, a rede (Wi-Fi, VLAN, firewall) não está alcançando a impressora e o problema não é a máquina.

### Limpar spooler
Para o serviço **Spooler**, apaga os trabalhos travados em `C:\Windows\System32\spool\PRINTERS` e inicia o serviço de novo. Resolve fila travada e boa parte dos casos de *"não consigo remover a impressora"*.

### Remover impressora + driver
Remove **todas** as impressoras cujo nome contém o texto do **Nome / filtro** e, em seguida, o driver delas, se nenhuma outra impressora o usar. Mostra OK/Falhou em cada passo.

Se o Windows não permitir remover o driver, use `printui /s /t2` → aba **Drivers** → **Remover** → **Remover driver e pacote de driver**.

### Remover fantasmas (PnP)
Remove os dispositivos Plug and Play cujo nome ou ID contém o filtro. É o que resolve a impressora que aparece em **Configurações → Impressoras e scanners** com *"Falha ao remover"*, mas que não existe mais no spooler.

Se der **acesso negado** mesmo como administrador, veja [Solução de problemas](SOLUCAO-DE-PROBLEMAS.md#acesso-negado-ao-remover-dispositivos-fantasma).

### Adicionar via IP (IPP)
Cria a impressora com o nome do **Nome / filtro**, apontando para `http://IP/ipp/print` com o **driver IPP nativo** do Windows (não precisa baixar driver do fabricante). Teste antes a porta 631 com **Testar portas do IP**.

Se o `Add-Printer` travar o PowerShell, a ferramenta abre o assistente **Adicionar impressora** do Windows e mostra o endereço para colar.

## Fluxo recomendado para impressora travada

1. **Listar impressoras** → anote nome, driver e porta.
2. **Limpar spooler**.
3. **Remover impressora + driver** com parte do nome.
4. Se ela continuar aparecendo nas Configurações: **Remover fantasmas (PnP)** com o modelo.
5. Reinicie a máquina.
6. Ache o IP (**Listar** numa máquina onde funciona, **DNS** ou **MAC/ARP**) → **Testar portas** → **Adicionar via IP**.
