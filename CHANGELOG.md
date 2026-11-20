# Histórico de versões

## [1.0.0] – 2026-11-20

Primeira versão publicada.

### Funções
- Interface gráfica (Windows Forms) com 8 ações: listar impressoras, achar IP por DNS e por MAC/ARP, testar portas, limpar spooler, remover impressora + driver, remover dispositivos fantasma (PnP) e adicionar impressora via IP (IPP).
- Elevação automática (UAC) e aviso quando roda sem administrador.
- Confirmação antes de ações que removem algo.
- Lançador `.bat` que contorna a política de execução.

### Robustez
- Cada ação roda num processo PowerShell separado (`-EncodedCommand`): falhas e travamentos aparecem na tela sem fechar a janela.
- Listagem e remoção via `Win32_Printer` / `Win32_PrinterDriver`, compatíveis com máquinas onde os cmdlets CDXML (`Get-Printer`) travam o PowerShell.
- Plano B para `Add-Printer`: abre o assistente do Windows se o comando travar.
- Log de erros da interface em `%TEMP%\ferramenta_impressoras.log`.
