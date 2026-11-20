# 🖨️ Ferramenta de Impressoras – Suporte TI

Ferramenta gráfica em **PowerShell** para técnicos de suporte resolverem os problemas de impressora mais comuns no Windows: **achar o IP**, **limpar o spooler**, **remover impressoras travadas, drivers e dispositivos fantasma** e **reinstalar pelo IP** — sem decorar comandos.

Não precisa instalar nada: roda em qualquer Windows 10/11 com o PowerShell que já vem no sistema. Funciona bem em atendimento remoto (TeamViewer, AnyDesk etc.).

![PowerShell](https://img.shields.io/badge/PowerShell-5.1-blue?logo=powershell) ![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows) ![Licença](https://img.shields.io/badge/licen%C3%A7a-MIT-green)

---

## ✨ Funções

| Botão | O que faz |
|---|---|
| **Listar impressoras** | Mostra impressoras instaladas, portas TCP/IP (com o IP) e drivers |
| **Achar IP (DNS)** | Resolve o nome da impressora no DNS da rede |
| **Achar IP (MAC/ARP)** | Procura o IP pelo final do MAC na tabela ARP |
| **Testar portas do IP** | Testa as portas 631 (IPP), 9100 (RAW) e 80 (painel web) |
| **Limpar spooler** | Para o serviço, esvazia a fila de impressão e inicia de novo |
| **Remover impressora + driver** | Remove as impressoras que batem com o filtro e o driver, se nenhuma outra o usar |
| **Remover fantasmas (PnP)** | Remove dispositivos WSD/IPP "fantasma" (o famoso *"Falha ao remover"*) |
| **Adicionar via IP (IPP)** | Reinstala a impressora pelo IP com o driver IPP nativo do Windows |

Ações que removem algo pedem confirmação antes de executar.

## 🚀 Como usar

1. Baixe o repositório (**Code → Download ZIP**) e extraia.
2. Mantenha `ferramenta_impressoras.ps1` e `Abrir_Ferramenta_Impressoras.bat` **na mesma pasta**.
3. Dê **duplo clique no `.bat`** e aceite o pedido de administrador (UAC).

> Se o Windows bloquear o script por ter vindo da internet, rode na pasta:
> ```powershell
> Get-ChildItem | Unblock-File
> ```

Sem administrador, a ferramenta abre mesmo assim, mas só as funções de consulta (listar e achar IP) funcionam.

📘 Guia completo de cada botão: [docs/GUIA-DE-USO.md](docs/GUIA-DE-USO.md)

## 🧱 Como funciona

- Interface em **Windows Forms**, escrita em PowerShell 5.1.
- **Cada ação roda num processo PowerShell separado** (via `-EncodedCommand`). Se um comando falhar ou travar, o erro aparece na tela e a janela continua aberta.
- A listagem e a remoção usam as classes WMI clássicas (`Win32_Printer`, `Win32_PrinterDriver`, `Win32_TCPIPPrinterPort`), que funcionam mesmo em máquinas onde os cmdlets `Get-Printer`/`Remove-Printer` travam (veja [Solução de problemas](docs/SOLUCAO-DE-PROBLEMAS.md#o-powershell-fecha-sozinho-ao-rodar-get-printer)).
- Se o `Add-Printer` travar, a ferramenta abre o assistente do Windows como **plano B**.
- Erros da própria interface são gravados em `%TEMP%\ferramenta_impressoras.log`.

## 📚 Documentação

- [Guia de uso](docs/GUIA-DE-USO.md) — passo a passo de cada função
- [Solução de problemas](docs/SOLUCAO-DE-PROBLEMAS.md) — impressora fantasma, acesso negado, máquina fora do domínio, PowerShell fechando sozinho
- [Comandos manuais](docs/COMANDOS-MANUAIS.md) — os mesmos procedimentos em comandos, para quando a ferramenta não estiver à mão
- [Histórico de versões](CHANGELOG.md)

## ⚠️ Limitações

- Remover dispositivos PnP criados pela descoberta de rede (WSD/IPP) pode exigir a conta **SYSTEM**; o procedimento está na documentação.
- Em máquinas fora do domínio, sem conta de administrador local (LAPS) ou credencial em cache, as remoções não funcionam.
- Impressoras distribuídas por **GPO/Intune** podem voltar sozinhas depois de removidas.

## 📄 Licença

[MIT](LICENSE) © Alessandro Dzindzik
