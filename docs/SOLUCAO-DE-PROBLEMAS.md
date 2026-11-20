# Solução de problemas

## Impressora com "Falha ao remover"

**Sintoma:** a impressora aparece em *Configurações → Impressoras e scanners* com o status **Falha ao remover**, e não dá para excluir nem adicionar de novo.

**Causa comum:** a fila e o driver já não existem no spooler (`Get-Printer` não a lista), mas sobraram **dispositivos PnP** criados pela descoberta automática de rede (WSD/IPP). Exemplo do que aparece:

```
FriendlyName : IMPRESSORA-01 (HP LaserJet MFP Modelo)
InstanceId   : SWD\DAFWSDPROVIDER\URN:UUID:xxxxxxxx-.../URI:xxxxxxxx-...
Class        : WSDPrintDevice

FriendlyName : HP LaserJet MFP Modelo [A1B2C3]
InstanceId   : SWD\IPP\xxxxxxxx-...
Class        : SoftwareDevice
```

**Solução:** botão **Remover fantasmas (PnP)** com o modelo no filtro, depois reinicie. Equivalente manual:

```powershell
Get-PnpDevice | Where-Object FriendlyName -like "*MODELO*" | ForEach-Object { pnputil /remove-device $_.InstanceId }
```

Para evitar que ela volte sozinha: em *Impressoras e scanners*, desative a instalação automática de dispositivos de rede e adicione a impressora manualmente pelo IP.

## Acesso negado ao remover dispositivos fantasma

1. Confirme que o PowerShell está elevado:
   ```powershell
   ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrators")
   ```
2. Se der `True` e ainda assim der acesso negado, os dispositivos WSD podem exigir a conta **SYSTEM**. Rode a remoção por uma tarefa agendada:
   ```powershell
   Set-Content C:\Windows\Temp\rmprinter.ps1 'Get-PnpDevice | Where-Object { $_.InstanceId -like "*PARTE_DO_ID*" } | ForEach-Object { pnputil /remove-device $_.InstanceId } *> C:\Windows\Temp\rmprinter.log'
   ```
   ```powershell
   Register-ScheduledTask -TaskName "RmPrinter" -Action (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Windows\Temp\rmprinter.ps1") -User "SYSTEM" -RunLevel Highest -Force
   ```
   ```powershell
   Start-ScheduledTask -TaskName "RmPrinter"; Start-Sleep 5; Get-Content C:\Windows\Temp\rmprinter.log
   ```
   ```powershell
   Unregister-ScheduledTask -TaskName "RmPrinter" -Confirm:$false; Remove-Item C:\Windows\Temp\rmprinter.ps1
   ```
3. Se nem como SYSTEM funcionar, provavelmente há política de restrição de dispositivos (GPO/Intune).

## Máquina fora do domínio (sem conta de administrador)

Com a máquina sem comunicação com o controlador de domínio, a conta de suporte só eleva se já tiver feito login nela antes (credencial em cache). Alternativas:

1. **LAPS**: use a senha do administrador local da máquina (`.\Administrador`).
2. **VPN**: se houver internet, conecte a VPN corporativa para a máquina enxergar o domínio de novo.
3. **Contornar**: adicione a impressora pelo IP via *Adicionar dispositivo → Adicionar manualmente → endereço IP* (IPP). Geralmente não exige administrador. O item fantasma continua na lista, mas a impressão funciona.
4. Faça a limpeza definitiva quando a máquina voltar para a rede.

## Descobrir o IP da impressora

| Onde | Comando |
|---|---|
| DNS | `Resolve-DnsName NOME-DA-IMPRESSORA` |
| Máquina onde ela já funciona | `Get-PrinterPort \| Select Name, PrinterHostAddress` |
| Servidor de impressão | `Get-Printer -ComputerName SERVIDOR \| Select Name, PortName` |
| Pelo MAC | `arp -a \| findstr /i "a1-b2-c3"` |
| Painel da impressora | Configurações → Rede → TCP/IP |

## O PowerShell fecha sozinho ao rodar Get-Printer

**Sintoma:** `Get-Printer` (e outros cmdlets como `Get-NetAdapter`, `Get-Disk`) fecha o PowerShell na hora, sem mensagem de erro. Código de saída `-1073741819`.

**Diagnóstico:**

```powershell
powershell -NoProfile -Command "Get-NetAdapter | Out-Null; 'ok'"; $LASTEXITCODE
```
```powershell
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000} -MaxEvents 10 | Where-Object Message -match 'powershell' | Select-Object -First 2 | Format-List TimeCreated, Message
```

Se o evento mostrar **módulo com falha `clr.dll`** e **código de exceção `0xc0000005`**, o problema está nas imagens nativas pré-compiladas (NGEN) do .NET Framework, que são usadas pela camada de cmdlets CDXML do PowerShell. O WMI e o spooler estão bons. Para confirmar, a consulta direta funciona:

```powershell
Get-CimInstance -Namespace root/StandardCimv2 -ClassName MSFT_Printer
```

**Correção** (PowerShell como administrador):

```powershell
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\ngen.exe update /force
```
```powershell
C:\Windows\Microsoft.NET\Framework\v4.0.30319\ngen.exe update /force
```

Reinicie e teste de novo. Se ainda falhar: `DISM /Online /Cleanup-Image /RestoreHealth`, `sfc /scannow` e, por último, a *Microsoft .NET Framework Repair Tool*.

> A ferramenta foi feita para continuar funcionando mesmo nessas máquinas: ela usa as classes `Win32_*` e roda cada ação num processo separado.

## A ferramenta não abre / o Windows bloqueia

- Abra sempre pelo `.bat`, que usa `-ExecutionPolicy Bypass`.
- Desbloqueie os arquivos baixados: `Get-ChildItem | Unblock-File`.
- Erros da interface ficam em `%TEMP%\ferramenta_impressoras.log`.
- Para ver erros no console:
  ```powershell
  powershell -NoExit -ExecutionPolicy Bypass -File .\ferramenta_impressoras.ps1
  ```
