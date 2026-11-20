# Comandos manuais

Os mesmos procedimentos da ferramenta, para rodar direto no PowerShell **como administrador**. Rode **um comando por linha** (ou separe com `;`) para não "grudar" ao colar no terminal.

## Achar o IP

```powershell
# Pelo nome (DNS)
Resolve-DnsName NOME-DA-IMPRESSORA

# Numa máquina onde ela já está instalada
Get-Printer | Select Name, PortName
Get-PrinterPort | Select Name, PrinterHostAddress

# No servidor de impressão
Get-Printer -ComputerName SERVIDOR | Where-Object Name -like "*PARTE*" | Select Name, PortName

# Testar se o IP responde (631 = IPP, 9100 = RAW)
Test-NetConnection IP -Port 631
```

```cmd
:: CMD – pelo final do MAC
arp -a | findstr /i "a1-b2-c3"
```

## Limpar o spooler

```powershell
Stop-Service Spooler -Force
Remove-Item C:\Windows\System32\spool\PRINTERS\* -Force
Start-Service Spooler
```

## Remover impressora e driver

```powershell
Get-Printer | Select Name, DriverName, Type
Remove-Printer -Name "NOME_EXATO"
Get-PrinterDriver | Select Name
Remove-PrinterDriver -Name "NOME_EXATO_DO_DRIVER"
```

Impressora conectada de servidor:

```powershell
printui /dn /n "\\SERVIDOR\NOME"
```

Driver em uso / pacote:

```powershell
pnputil /enum-drivers | Select-String -Context 0,6 "MODELO"
pnputil /delete-driver oemXX.inf /uninstall /force
```

```cmd
:: CMD – alternativas
printui /dl /n "NOME_EXATO"
printui /s /t2
```

## Remover dispositivos fantasma

```powershell
Get-PnpDevice | Where-Object { $_.FriendlyName -like "*MODELO*" } | Format-List FriendlyName, InstanceId, Class, Status
Get-PnpDevice | Where-Object FriendlyName -like "*MODELO*" | ForEach-Object { pnputil /remove-device $_.InstanceId }
```

## Último recurso: registro

Com o spooler **parado**, apague:

- `HKLM\SYSTEM\CurrentControlSet\Control\Print\Printers\NOME`
- `HKCU\Printers\Connections\,,SERVIDOR,NOME` (impressora de servidor)

Depois inicie o spooler e reinicie a máquina.

## Reinstalar pelo IP

```powershell
# Driver IPP nativo do Windows (sem baixar driver)
Add-Printer -Name "NOME" -IppURL "http://IP/ipp/print"

# Com driver do fabricante já instalado
Add-PrinterPort -Name "IP_IP" -PrinterHostAddress "IP"
Add-Printer -Name "NOME" -DriverName "NOME_DO_DRIVER" -PortName "IP_IP"
```
