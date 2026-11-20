# Ferramenta de Impressoras - Suporte TI
# Localizar IP, remover impressora/driver/fantasmas e reinstalar via IPP.
# Cada acao roda num processo PowerShell separado: se um comando falhar, a janela continua aberta.
# Log de erros da interface: %TEMP%\ferramenta_impressoras.log

$logArquivo = Join-Path $env:TEMP "ferramenta_impressoras.log"
function Grava-Log($msg) { try { Add-Content -Path $logArquivo -Value ("[{0}] {1}" -f (Get-Date -Format "dd/MM HH:mm:ss"), $msg) } catch {} }

# --- Elevacao ---
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$ehAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $ehAdmin -and $PSCommandPath) {
    try {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        exit
    } catch { }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetUnhandledExceptionMode([System.Windows.Forms.UnhandledExceptionMode]::CatchException)
[System.Windows.Forms.Application]::add_ThreadException({ param($s, $e) Grava-Log ("ThreadException: " + $e.Exception.ToString()) })
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# --- Janela ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Ferramenta de Impressoras - Suporte TI"
$form.Size = New-Object System.Drawing.Size(940, 650)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

function Novo-Campo($rotulo, $y, $padrao) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $rotulo; $l.Location = New-Object System.Drawing.Point(12, ($y + 3)); $l.Size = New-Object System.Drawing.Size(100, 20)
    $form.Controls.Add($l)
    $t = New-Object System.Windows.Forms.TextBox
    $t.Location = New-Object System.Drawing.Point(115, $y); $t.Size = New-Object System.Drawing.Size(320, 22); $t.Text = $padrao
    $form.Controls.Add($t)
    return $t
}
$txtNome = Novo-Campo "Nome / filtro:" 12 ""
$txtIP   = Novo-Campo "IP:"            40 ""
$txtMAC  = Novo-Campo "Final do MAC:"  68 ""

$saida = New-Object System.Windows.Forms.TextBox
$saida.Multiline = $true; $saida.ScrollBars = [System.Windows.Forms.ScrollBars]::Both; $saida.WordWrap = $false; $saida.ReadOnly = $true
$saida.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$saida.BackColor = [System.Drawing.Color]::FromArgb(17, 17, 17); $saida.ForeColor = [System.Drawing.Color]::Gainsboro
$saida.Location = New-Object System.Drawing.Point(12, 175); $saida.Size = New-Object System.Drawing.Size(900, 400)
$saida.Anchor = [System.Windows.Forms.AnchorStyles]"Top, Bottom, Left, Right"
$form.Controls.Add($saida)

function Log($texto) {
    $saida.AppendText(([string]$texto -replace "`r?`n", "`r`n") + "`r`n")
}

# Texto seguro dentro de aspas simples no PowerShell
function Q($t) { "'" + ([string]$t).Replace("'", "''") + "'" }

# Roda o codigo num powershell.exe separado e devolve a saida como texto
function Rodar-PS($codigo) {
    $completo = "[Console]::OutputEncoding=[Text.Encoding]::UTF8; `$ErrorActionPreference='Continue'; " + $codigo
    $b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($completo))
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand $b64"
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [Text.Encoding]::UTF8
    $p = [System.Diagnostics.Process]::Start($psi)
    $errTask = $p.StandardError.ReadToEndAsync()
    $out = $p.StandardOutput.ReadToEnd()
    $p.WaitForExit()
    $err = $errTask.Result
    $codigoSaida = $p.ExitCode
    $script:ultimoCodigo = $codigoSaida
    # remove o "lixo" de progresso/CLIXML que o PowerShell manda no stderr
    if ($err -match "#< CLIXML") {
        $msgs = [regex]::Matches($err, '<S S="Error">(.*?)</S>') | ForEach-Object { $_.Groups[1].Value -replace "_x000D__x000A_", "`r`n" }
        $err = ($msgs -join "")
    }
    $res = ($out + "`r`n" + $err).Trim()
    if ($codigoSaida -ne 0 -and $codigoSaida -ne 1) {
        $res += "`r`n[!] O processo do PowerShell foi encerrado de forma anormal (código $codigoSaida). Algum comando travou o PowerShell nesta máquina."
    }
    return $res
}

function Executar($acao) {
    try {
        if ($acao.C) {
            $r = [System.Windows.Forms.MessageBox]::Show("Executar '$($acao.T)'?", "Confirmar", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }
        }
        Log ""
        Log (">>> " + $acao.T + " ...")
        $codigo = & $acao.A
        if ($codigo -like "!*") { Log $codigo.Substring(1); return }
        $form.UseWaitCursor = $true
        [System.Windows.Forms.Application]::DoEvents()
        $script:ultimoCodigo = 0
        $res = Rodar-PS $codigo
        if ([string]::IsNullOrWhiteSpace($res)) { $res = "(sem saída)" }
        Log $res
        if ($acao.F -and $script:ultimoCodigo -ne 0 -and $script:ultimoCodigo -ne 1) {
            Log "--- Usando o plano B ---"
            Log (Rodar-PS (& $acao.F))
        }
    } catch {
        Log ("ERRO: " + $_.Exception.Message)
        Grava-Log ("Executar/" + $acao.T + ": " + $_.Exception.ToString())
    } finally {
        $form.UseWaitCursor = $false
    }
}

# --- Acoes: cada uma devolve o codigo PowerShell a rodar, ou "!mensagem" ---
$acoes = @(
    @{ T = "Listar impressoras"; C = $false; A = {
        "'== IMPRESSORAS =='; Get-CimInstance Win32_Printer | Format-Table Name, DriverName, PortName, Network, Default -AutoSize | Out-String -Width 250; " +
        "'== PORTAS TCP/IP =='; Get-CimInstance Win32_TCPIPPrinterPort | Format-Table Name, HostAddress, PortNumber -AutoSize | Out-String -Width 250; " +
        "'== DRIVERS =='; Get-CimInstance Win32_PrinterDriver | ForEach-Object { (`$_.Name -split ',')[0] } | Sort-Object -Unique | Out-String -Width 250" } },

    @{ T = "Achar IP (DNS)"; C = $false; A = {
        $n = $txtNome.Text.Trim()
        if (-not $n) { return "!Informe o nome da impressora." }
        "try { Resolve-DnsName $(Q $n) -ErrorAction Stop | Format-Table Name, IPAddress -AutoSize | Out-String -Width 250 } " +
        "catch { 'Nome nao encontrado no DNS desta rede. Tente pelo MAC/ARP, pelo servidor de impressao ou pelo painel da impressora.' }" } },

    @{ T = "Achar IP (MAC/ARP)"; C = $false; A = {
        $m = ($txtMAC.Text.Trim() -replace "[:\s]", "-").ToLower()
        if ($m.Length -eq 6 -and $m -notmatch "-") { $m = "{0}-{1}-{2}" -f $m.Substring(0,2), $m.Substring(2,2), $m.Substring(4,2) }
        if (-not $m) { return "!Informe o final do MAC (ex.: A1B2C3)." }
        "`$r = arp -a | Select-String -SimpleMatch $(Q $m); if (`$r) { `$r | Out-String } else { 'Nada encontrado na tabela ARP. Pingue a faixa da rede e tente de novo.' }" } },

    @{ T = "Testar portas do IP"; C = $false; A = {
        $ip = $txtIP.Text.Trim()
        if (-not $ip) { return "!Informe o IP." }
        "foreach (`$p in 631, 9100, 80) { `$t = Test-NetConnection $(Q $ip) -Port `$p -WarningAction SilentlyContinue; " +
        "'Porta {0}: {1}' -f `$p, `$(if (`$t.TcpTestSucceeded) { 'ABERTA' } else { 'fechada' }) }" } },

    @{ T = "Limpar spooler"; C = $true; A = {
        "Stop-Service Spooler -Force; Remove-Item 'C:\Windows\System32\spool\PRINTERS\*' -Force -ErrorAction SilentlyContinue; " +
        "Start-Service Spooler; Get-Service Spooler | Format-Table Name, Status -AutoSize | Out-String" } },

    @{ T = "Remover impressora + driver"; C = $true; A = {
        $f = $txtNome.Text.Trim()
        if (-not $f) { return "!Informe o nome (ou parte do nome)." }
        "`$imps = @(Get-CimInstance Win32_Printer | Where-Object Name -like $(Q "*$f*")); " +
        "if (-not `$imps) { 'Nenhuma impressora encontrada com esse filtro.' }; " +
        "foreach (`$i in `$imps) { `$drv = `$i.DriverName; 'Removendo impressora: ' + `$i.Name; " +
        "  try { Remove-CimInstance -InputObject `$i -ErrorAction Stop; '  OK' } catch { '  Falhou: ' + `$_.Exception.Message; continue }; " +
        "  if (`$drv -and -not (Get-CimInstance Win32_Printer | Where-Object DriverName -eq `$drv)) { 'Removendo driver: ' + `$drv; " +
        "    try { Get-CimInstance Win32_PrinterDriver | Where-Object { (`$_.Name -split ',')[0] -eq `$drv } | Remove-CimInstance -ErrorAction Stop; '  OK' } " +
        "    catch { '  Nao foi possivel remover o driver: ' + `$_.Exception.Message; '  Alternativa: printui /s /t2 > aba Drivers > Remover > Remover driver e pacote.' } } }" } },

    @{ T = "Remover fantasmas (PnP)"; C = $true; A = {
        $f = $txtNome.Text.Trim()
        if (-not $f) { return "!Informe um filtro (ex.: modelo ou parte do nome)." }
        "`$devs = Get-PnpDevice | Where-Object { `$_.FriendlyName -like $(Q "*$f*") -or `$_.InstanceId -like $(Q "*$f*") }; " +
        "if (-not `$devs) { 'Nenhum dispositivo encontrado.' }; " +
        "foreach (`$d in `$devs) { '-> ' + `$d.FriendlyName + ' | ' + `$d.InstanceId; pnputil /remove-device `$d.InstanceId | Out-String }" } },

    @{ T = "Adicionar via IP (IPP)"; C = $false; A = {
        $n = $txtNome.Text.Trim(); $ip = $txtIP.Text.Trim()
        if (-not $n -or -not $ip) { return "!Informe o nome desejado e o IP." }
        "Add-Printer -Name $(Q $n) -IppURL $(Q "http://$ip/ipp/print") -ErrorAction Stop; " +
        "Get-CimInstance Win32_Printer | Where-Object Name -eq $(Q $n) | Format-List Name, DriverName, PortName | Out-String" };
      F = {
        "'O Add-Printer travou nesta maquina. Abrindo o assistente do Windows para adicionar manualmente.'; " +
        "'No assistente: A impressora que eu quero nao esta na lista > Selecionar impressora compartilhada pelo nome > http://$($txtIP.Text.Trim())/ipp/print'; " +
        "Start-Process rundll32.exe -ArgumentList 'printui.dll,PrintUIEntry /il'" } }
)

# --- Botoes (2 linhas x 4) ---
for ($i = 0; $i -lt $acoes.Count; $i++) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $acoes[$i].T
    $b.Size = New-Object System.Drawing.Size(218, 30)
    $b.Location = New-Object System.Drawing.Point((12 + ($i % 4) * 225), (100 + [math]::Floor($i / 4) * 36))
    $b.Tag = $i
    $b.Add_Click({ param($s, $ev) Executar $acoes[[int]$s.Tag] })
    $form.Controls.Add($b)
}

$btnLimpar = New-Object System.Windows.Forms.Button
$btnLimpar.Text = "Limpar tela"; $btnLimpar.Size = New-Object System.Drawing.Size(110, 28)
$btnLimpar.Location = New-Object System.Drawing.Point(12, 582); $btnLimpar.Anchor = [System.Windows.Forms.AnchorStyles]"Bottom, Left"
$btnLimpar.Add_Click({ $saida.Clear() })
$form.Controls.Add($btnLimpar)

if ($ehAdmin) { Log "Executando como ADMINISTRADOR." }
else { Log "ATENÇÃO: sem privilégio de administrador. Listar e achar IP funcionam; remover não." }

try {
    [void]$form.ShowDialog()
} catch {
    Grava-Log ("ShowDialog: " + $_.Exception.ToString())
    [System.Windows.Forms.MessageBox]::Show("Erro inesperado. Detalhes em: $logArquivo", "Ferramenta de Impressoras") | Out-Null
}
