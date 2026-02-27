param(
    [switch]$SkipConfirm
)

# ============================================
#  OpenNotebook 自動セットアップスクリプト
# ============================================

$ErrorActionPreference = "Stop"
$InstallDir = "C:\OpenNotebook"
$ComposeUrl = "https://raw.githubusercontent.com/lfnovo/open-notebook/main/docker-compose.yml"
$DockerInstallerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
$AppUrl = "http://localhost:8502"

# --- ステップ1: 開始メッセージ＆事前案内 ---
try {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  OpenNotebook 自動セットアップツール" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "このツールは OpenNotebook を自動でセットアップします。"
    Write-Host ""
    if (-not $SkipConfirm) {
        Write-Host "【ご注意】" -ForegroundColor Yellow
        Write-Host "Docker Desktop が未インストールの場合、自動でインストールを行います。"
        Write-Host "その場合、PCの再起動が必要になることがあります。"
        Write-Host "作業中のファイルがあれば、事前に保存してください。"
        Write-Host ""
        $confirm = Read-Host "続行しますか？ (Y/N)"
        if ($confirm -ne "Y" -and $confirm -ne "y") {
            Write-Host "セットアップを中止しました。" -ForegroundColor Yellow
            exit 0
        }
    }
} catch {
    Write-Host "【エラー】ステップ1: 開始処理でエラーが発生しました: $_" -ForegroundColor Red
    exit 1
}

# --- ステップ2: 管理者権限チェック ---
try {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host "管理者権限が必要です。管理者として再起動します..." -ForegroundColor Yellow
        $scriptPath = $MyInvocation.MyCommand.Definition
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -NoExit -File `"$scriptPath`" -SkipConfirm" -Verb RunAs
        exit 0
    }
    Write-Host "[OK] 管理者権限で実行中です。" -ForegroundColor Green
} catch {
    Write-Host "【エラー】ステップ2: 管理者権限の取得に失敗しました: $_" -ForegroundColor Red
    exit 1
}

# --- ステップ3: Docker Desktop チェック ---
$dockerInstalled = $false
try {
    $dockerVer = docker --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $dockerInstalled = $true
        Write-Host "[OK] Docker が検出されました: $dockerVer" -ForegroundColor Green
    }
} catch {
    $dockerInstalled = $false
}

# docker CLI が見つからなくても Docker Desktop 本体がインストール済みか確認（再起動後のPATH未反映対策）
if (-not $dockerInstalled) {
    $dockerDesktopExe = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerDesktopExe) {
        Write-Host "[OK] Docker Desktop はインストール済みです。CLIパスを検索中..." -ForegroundColor Yellow
        # レジストリから最新の PATH を取得して反映
        $machinePath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        $env:PATH = "$machinePath;$userPath"

        # まだ見つからない場合、既知のインストール先から docker.exe を直接探す
        try {
            docker --version 2>&1 | Out-Null
        } catch {
            $dockerCliCandidates = @(
                "C:\Program Files\Docker\Docker\resources\bin",
                "C:\Program Files\Docker\Docker\resources",
                "C:\Program Files\Docker\Docker",
                "$env:LOCALAPPDATA\Docker\resources\bin",
                "$env:ProgramFiles\Docker\Docker\resources\bin"
            )
            foreach ($candidate in $dockerCliCandidates) {
                if (Test-Path (Join-Path $candidate "docker.exe")) {
                    Write-Host "  docker.exe を検出: $candidate" -ForegroundColor Gray
                    $env:PATH = "$candidate;$env:PATH"
                    break
                }
            }
        }

        $dockerInstalled = $true
        try {
            $dockerVer = docker --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] Docker が検出されました: $dockerVer" -ForegroundColor Green
            }
        } catch {
            Write-Host "【警告】Docker Desktop はインストール済みですが、docker.exe が見つかりません。" -ForegroundColor Yellow
            Write-Host "  Docker Desktop を一度手動で起動してから、再度このスクリプトを実行してください。" -ForegroundColor Yellow
            exit 1
        }
    }
}

# --- ステップ4: Docker Desktop 自動インストール ---
if (-not $dockerInstalled) {
    try {
        Write-Host ""
        Write-Host "Docker Desktop が見つかりませんでした。自動インストールを開始します..." -ForegroundColor Yellow
        $installerPath = "$env:TEMP\DockerDesktopInstaller.exe"

        Write-Host "Docker Desktop をダウンロード中です。しばらくお待ちください..." -ForegroundColor Cyan
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $DockerInstallerUrl -OutFile $installerPath -UseBasicParsing
        $ProgressPreference = 'Continue'
        Write-Host "[OK] ダウンロードが完了しました。" -ForegroundColor Green

        Write-Host "Docker Desktop をインストール中です。しばらくお待ちください..." -ForegroundColor Cyan
        Start-Process -Wait -FilePath $installerPath -ArgumentList "install", "--quiet", "--accept-license"
        Write-Host "[OK] Docker Desktop のインストールが完了しました。" -ForegroundColor Green

        # 一時ファイル削除
        Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue

        Write-Host ""
        Write-Host "Docker Desktop のインストールが完了しました。" -ForegroundColor Green
        Write-Host "PCを再起動する必要がある場合があります。" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "再起動後、もう一度このスクリプトを実行してください。" -ForegroundColor Yellow
        $restartConfirm = Read-Host "今すぐPCを再起動しますか？ (Y/N)"
        if ($restartConfirm -eq "Y" -or $restartConfirm -eq "y") {
            Restart-Computer
            exit 0
        } else {
            Write-Host "再起動後にもう一度このスクリプトを実行してください。" -ForegroundColor Yellow
            exit 0
        }
    } catch {
        Write-Host "【エラー】ステップ4: Docker Desktop のインストールに失敗しました: $_" -ForegroundColor Red
        exit 1
    }
}

# --- ステップ5: Docker Desktop 起動チェック ---
try {
    $dockerRunning = $false
    try {
        docker info 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $dockerRunning = $true
        }
    } catch {
        $dockerRunning = $false
    }

    if (-not $dockerRunning) {
        Write-Host "Docker Desktop を起動中です。しばらくお待ちください..." -ForegroundColor Cyan
        $dockerExePath = $null
        $dockerExeCandidates = @(
            "C:\Program Files\Docker\Docker\Docker Desktop.exe",
            "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
        )
        foreach ($candidate in $dockerExeCandidates) {
            if (Test-Path $candidate) {
                $dockerExePath = $candidate
                break
            }
        }
        if (-not $dockerExePath) {
            Write-Host "【エラー】ステップ5: Docker Desktop の実行ファイルが見つかりません。" -ForegroundColor Red
            exit 1
        }
        Start-Process $dockerExePath

        $elapsed = 0
        $maxWait = 120
        while ($elapsed -lt $maxWait) {
            Start-Sleep -Seconds 5
            $elapsed += 5
            Write-Host "  Docker Desktop の起動を待機中... ($elapsed/$maxWait 秒)" -ForegroundColor Gray
            try {
                docker info 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    $dockerRunning = $true
                    break
                }
            } catch {
                # まだ起動していない
            }
        }

        if (-not $dockerRunning) {
            Write-Host "【エラー】ステップ5: Docker Desktop の起動がタイムアウトしました（${maxWait}秒）。" -ForegroundColor Red
            Write-Host "Docker Desktop を手動で起動してから、もう一度このスクリプトを実行してください。" -ForegroundColor Yellow
            exit 1
        }
    }
    Write-Host "[OK] Docker Desktop が起動しています。" -ForegroundColor Green
} catch {
    Write-Host "【エラー】ステップ5: Docker Desktop の起動チェックに失敗しました: $_" -ForegroundColor Red
    exit 1
}

# --- ステップ6: インストール先ディレクトリ作成 ---
try {
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
        Write-Host "[OK] インストール先ディレクトリを作成しました: $InstallDir" -ForegroundColor Green
    } else {
        Write-Host "[OK] インストール先ディレクトリは既に存在します: $InstallDir" -ForegroundColor Green
    }
} catch {
    Write-Host "【エラー】ステップ6: ディレクトリの作成に失敗しました: $_" -ForegroundColor Red
    exit 1
}

# --- ステップ7: docker-compose.yml ダウンロード ---
try {
    $composePath = Join-Path $InstallDir "docker-compose.yml"
    if (Test-Path $composePath) {
        $overwrite = Read-Host "docker-compose.yml は既に存在します。上書きしますか？ (Y/N)"
        if ($overwrite -ne "Y" -and $overwrite -ne "y") {
            Write-Host "既存の docker-compose.yml を使用します。" -ForegroundColor Yellow
        } else {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $ComposeUrl -OutFile $composePath -UseBasicParsing
            Write-Host "[OK] docker-compose.yml を上書きダウンロードしました。" -ForegroundColor Green
        }
    } else {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $ComposeUrl -OutFile $composePath -UseBasicParsing
        Write-Host "[OK] docker-compose.yml をダウンロードしました。" -ForegroundColor Green
    }
} catch {
    Write-Host "【エラー】ステップ7: docker-compose.yml のダウンロードに失敗しました: $_" -ForegroundColor Red
    exit 1
}

# --- ステップ8: 暗号化キー自動生成＆書き込み ---
try {
    $composePath = Join-Path $InstallDir "docker-compose.yml"
    $composeContent = Get-Content -Path $composePath -Raw

    if ($composeContent -match "OPEN_NOTEBOOK_ENCRYPTION_KEY=change-me-to-a-secret-string") {
        # ランダムな32文字の英数字文字列を生成
        $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        $encryptionKey = -join ((1..32) | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })

        $composeContent = $composeContent -replace "OPEN_NOTEBOOK_ENCRYPTION_KEY=change-me-to-a-secret-string", "OPEN_NOTEBOOK_ENCRYPTION_KEY=$encryptionKey"
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($composePath, $composeContent, $utf8NoBom)
        Write-Host "[OK] 暗号化キーを自動生成して設定しました。" -ForegroundColor Green
    } else {
        Write-Host "[OK] 暗号化キーは既にカスタム値が設定されています。スキップします。" -ForegroundColor Green
    }
} catch {
    Write-Host "【エラー】ステップ8: 暗号化キーの設定に失敗しました: $_" -ForegroundColor Red
    exit 1
}

# --- ステップ9: docker compose up ---
try {
    Write-Host ""
    Write-Host "OpenNotebook を起動中です（初回はイメージのダウンロードに数分かかります）..." -ForegroundColor Cyan
    Set-Location -Path $InstallDir
    # Start-Process で実行し、stderr を PowerShell のエラーハンドリングから分離する
    $process = Start-Process -FilePath "docker" -ArgumentList "compose", "up", "-d" -WorkingDirectory $InstallDir -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -ne 0) {
        throw "docker compose up -d がエラーコード $($process.ExitCode) で失敗しました"
    }
    Write-Host "[OK] コンテナを起動しました。" -ForegroundColor Green
} catch {
    Write-Host "【エラー】ステップ9: docker compose up に失敗しました: $_" -ForegroundColor Red
    exit 1
}

# --- ステップ10: ヘルスチェック ---
try {
    $elapsed = 0
    $maxWait = 120
    $healthy = $false

    Write-Host "サービスの起動を待機中です..." -ForegroundColor Cyan
    while ($elapsed -lt $maxWait) {
        Start-Sleep -Seconds 5
        $elapsed += 5
        Write-Host "  サービスの起動を待機中です... ($elapsed/$maxWait 秒)" -ForegroundColor Gray
        try {
            $response = Invoke-WebRequest -Uri $AppUrl -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                $healthy = $true
                break
            }
        } catch {
            # まだ起動していない
        }
    }

    if (-not $healthy) {
        Write-Host "【エラー】ステップ10: サービスの起動がタイムアウトしました（${maxWait}秒）。" -ForegroundColor Red
        Write-Host "docker compose logs で詳細を確認してください。" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "[OK] サービスが正常に起動しました。" -ForegroundColor Green
} catch {
    Write-Host "【エラー】ステップ10: ヘルスチェックに失敗しました: $_" -ForegroundColor Red
    exit 1
}

# --- ステップ11: ランチャー配置＆デスクトップショートカット作成 ---
try {
    $launcherDest = Join-Path $InstallDir "open-notebook-launcher.ps1"
    $launcherSrc = Join-Path $PSScriptRoot "open-notebook-launcher.ps1"

    if (Test-Path $launcherSrc) {
        Copy-Item -Path $launcherSrc -Destination $launcherDest -Force
        Write-Host "[OK] ランチャーを配置しました: $launcherDest" -ForegroundColor Green
    } else {
        # ランチャーファイルが同梱されていない場合は埋め込みコードから生成
        Write-Host "ランチャーファイルが見つからないため、埋め込みコードから生成します..." -ForegroundColor Yellow
        $launcherCode = @'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$InstallDir = "C:\OpenNotebook"
$AppUrl = "http://localhost:8502"

# --- メインフォーム ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Open Notebook ランチャー"
$form.Size = New-Object System.Drawing.Size(350, 295)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

# --- ステータスラベル ---
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Size = New-Object System.Drawing.Size(300, 30)
$statusLabel.Location = New-Object System.Drawing.Point(20, 15)
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$statusLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($statusLabel)

# --- Docker 起動ボタン ---
$dockerButton = New-Object System.Windows.Forms.Button
$dockerButton.Text = "🐳 Docker Desktop を起動"
$dockerButton.Size = New-Object System.Drawing.Size(300, 35)
$dockerButton.Location = New-Object System.Drawing.Point(20, 55)
$dockerButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Controls.Add($dockerButton)

# --- 起動ボタン ---
$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "▶ 起動"
$startButton.Size = New-Object System.Drawing.Size(300, 35)
$startButton.Location = New-Object System.Drawing.Point(20, 100)
$startButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Controls.Add($startButton)

# --- ブラウザで開くボタン ---
$openButton = New-Object System.Windows.Forms.Button
$openButton.Text = "🌐 ブラウザで開く"
$openButton.Size = New-Object System.Drawing.Size(300, 35)
$openButton.Location = New-Object System.Drawing.Point(20, 145)
$openButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Controls.Add($openButton)

# --- 停止ボタン ---
$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Text = "■ 停止"
$stopButton.Size = New-Object System.Drawing.Size(300, 35)
$stopButton.Location = New-Object System.Drawing.Point(20, 190)
$stopButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Controls.Add($stopButton)

# --- ステータス確認関数 ---
function Update-Status {
    try {
        $dockerInfo = docker info 2>&1
        if ($LASTEXITCODE -ne 0) {
            $statusLabel.Text = "● Docker 未起動"
            $statusLabel.ForeColor = [System.Drawing.Color]::Gray
            return
        }
    } catch {
        $statusLabel.Text = "● Docker 未起動"
        $statusLabel.ForeColor = [System.Drawing.Color]::Gray
        return
    }
    try {
        $output = docker compose -f "$InstallDir\docker-compose.yml" ps --format "{{.State}}" 2>&1
        if ($LASTEXITCODE -eq 0 -and $output -match "running") {
            $statusLabel.Text = "● 起動中"
            $statusLabel.ForeColor = [System.Drawing.Color]::Green
        } else {
            $statusLabel.Text = "● 停止中"
            $statusLabel.ForeColor = [System.Drawing.Color]::Red
        }
    } catch {
        $statusLabel.Text = "● 停止中"
        $statusLabel.ForeColor = [System.Drawing.Color]::Red
    }
}

# --- Docker 起動チェック関数 ---
function Test-DockerRunning {
    try {
        docker info 2>&1 | Out-Null
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

# --- Docker 起動ボタン処理 ---
$dockerButton.Add_Click({
    if (Test-DockerRunning) {
        [System.Windows.Forms.MessageBox]::Show(
            "Docker Desktop は既に起動しています。",
            "情報",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        return
    }

    $dockerExe = $null
    $candidates = @(
        "C:\Program Files\Docker\Docker\Docker Desktop.exe",
        "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
    )
    foreach ($path in $candidates) {
        if (Test-Path $path) {
            $dockerExe = $path
            break
        }
    }

    if (-not $dockerExe) {
        [System.Windows.Forms.MessageBox]::Show(
            "Docker Desktop が見つかりません。`nインストールされているか確認してください。",
            "エラー",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return
    }

    $dockerButton.Enabled = $false
    $dockerButton.Text = "Docker 起動中..."
    $statusLabel.Text = "● Docker 起動中..."
    $statusLabel.ForeColor = [System.Drawing.Color]::Orange
    $form.Refresh()

    Start-Process $dockerExe

    $script:dockerWaitTimer = New-Object System.Windows.Forms.Timer
    $script:dockerWaitTimer.Interval = 3000
    $script:dockerWaitCount = 0
    $script:dockerWaitTimer.Add_Tick({
        $script:dockerWaitCount++
        if (Test-DockerRunning) {
            $script:dockerWaitTimer.Stop()
            $script:dockerWaitTimer.Dispose()
            $dockerButton.Text = "🐳 Docker Desktop を起動"
            $dockerButton.Enabled = $true
            Update-Status
        } elseif ($script:dockerWaitCount -ge 40) {
            $script:dockerWaitTimer.Stop()
            $script:dockerWaitTimer.Dispose()
            $dockerButton.Text = "🐳 Docker Desktop を起動"
            $dockerButton.Enabled = $true
            $statusLabel.Text = "● Docker 起動失敗"
            $statusLabel.ForeColor = [System.Drawing.Color]::Red
        }
    })
    $script:dockerWaitTimer.Start()
})

# --- 起動ボタン処理 ---
$startButton.Add_Click({
    if (-not (Test-DockerRunning)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Docker Desktop が起動していません。`n先に「Docker Desktop を起動」ボタンを押してください。",
            "エラー",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return
    }

    $startButton.Enabled = $false
    $stopButton.Enabled = $false
    $startButton.Text = "起動中..."
    $statusLabel.Text = "● 起動処理中..."
    $statusLabel.ForeColor = [System.Drawing.Color]::Orange
    $form.Refresh()

    $script:startJob = Start-Job -ScriptBlock {
        param($dir)
        Set-Location $dir
        docker compose up -d 2>&1
    } -ArgumentList $InstallDir

    $script:startTimer = New-Object System.Windows.Forms.Timer
    $script:startTimer.Interval = 1000
    $script:startTimer.Add_Tick({
        if ($script:startJob.State -eq "Completed" -or $script:startJob.State -eq "Failed") {
            $script:startTimer.Stop()
            $script:startTimer.Dispose()

            $script:waitTimer = New-Object System.Windows.Forms.Timer
            $script:waitTimer.Interval = 15000
            $script:waitTimer.Add_Tick({
                $script:waitTimer.Stop()
                $script:waitTimer.Dispose()
                Update-Status
                $startButton.Text = "▶ 起動"
                $startButton.Enabled = $true
                $stopButton.Enabled = $true
                Start-Process $AppUrl
            })
            $script:waitTimer.Start()
        }
    })
    $script:startTimer.Start()
})

# --- ブラウザで開くボタン処理 ---
$openButton.Add_Click({
    Start-Process $AppUrl
})

# --- 停止ボタン処理 ---
$stopButton.Add_Click({
    if (-not (Test-DockerRunning)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Docker Desktop が起動していません。",
            "エラー",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return
    }

    $startButton.Enabled = $false
    $stopButton.Enabled = $false
    $stopButton.Text = "停止中..."
    $statusLabel.Text = "● 停止処理中..."
    $statusLabel.ForeColor = [System.Drawing.Color]::Orange
    $form.Refresh()

    $script:stopJob = Start-Job -ScriptBlock {
        param($dir)
        Set-Location $dir
        docker compose down 2>&1
    } -ArgumentList $InstallDir

    $script:stopTimer = New-Object System.Windows.Forms.Timer
    $script:stopTimer.Interval = 1000
    $script:stopTimer.Add_Tick({
        if ($script:stopJob.State -eq "Completed" -or $script:stopJob.State -eq "Failed") {
            $script:stopTimer.Stop()
            $script:stopTimer.Dispose()
            Update-Status
            $stopButton.Text = "■ 停止"
            $startButton.Enabled = $true
            $stopButton.Enabled = $true
        }
    })
    $script:stopTimer.Start()
})

# --- フォームクローズ時にジョブをクリーンアップ ---
$form.Add_FormClosing({
    Get-Job | Where-Object { $_.State -eq "Running" } | Stop-Job -PassThru | Remove-Job
})

# --- 初期ステータス確認 ---
Update-Status

# --- フォーム表示 ---
[System.Windows.Forms.Application]::Run($form)
'@
        Set-Content -Path $launcherDest -Value $launcherCode -Encoding UTF8
        Write-Host "[OK] ランチャーを生成・配置しました: $launcherDest" -ForegroundColor Green
    }

    # デスクトップショートカット作成
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "Open Notebook.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$launcherDest`""
    $shortcut.WorkingDirectory = $InstallDir
    $shortcut.IconLocation = "shell32.dll,1"
    $shortcut.Description = "Open Notebook ランチャー"
    $shortcut.Save()
    Write-Host "[OK] デスクトップにショートカットを作成しました: $shortcutPath" -ForegroundColor Green
} catch {
    Write-Host "【エラー】ステップ11: ランチャーの配置またはショートカットの作成に失敗しました: $_" -ForegroundColor Red
    exit 1
}

# --- ステップ12: ブラウザで自動オープン ---
try {
    Start-Process $AppUrl
    Write-Host "[OK] ブラウザで OpenNotebook を開きました。" -ForegroundColor Green
} catch {
    Write-Host "【エラー】ステップ12: ブラウザの起動に失敗しました: $_" -ForegroundColor Red
    exit 1
}

# --- ステップ13: 完了メッセージ ---
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  セットアップが完了しました！" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "OpenNotebook が起動しました。"
Write-Host "ブラウザで $AppUrl が開かれます。"
Write-Host ""
Write-Host "デスクトップに「Open Notebook」ショートカットが作成されました。"
Write-Host "次回以降はショートカットからランチャーを起動できます。"
Write-Host ""
Write-Host "初回セットアップ:" -ForegroundColor Yellow
Write-Host "  Settings → API Keys からAIプロバイダーのAPIキーを設定してください。" -ForegroundColor Yellow
Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "【Ollama でローカルLLMを使う場合】" -ForegroundColor Cyan
Write-Host ""

Write-Host "  1. Ollama をインストール: https://ollama.com/download" -ForegroundColor White
Write-Host ""
Write-Host "  2. 必要なモデルをダウンロード:" -ForegroundColor White
Write-Host "     ollama pull mxbai-embed-large   (Embeddingモデル・必須)" -ForegroundColor Gray
Write-Host "     ollama pull gemma3              (チャットモデル・推奨)" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. OpenNotebook の Settings で以下を設定:" -ForegroundColor White
Write-Host "     - Provider: Ollama" -ForegroundColor Gray
Write-Host "     - Base URL: http://host.docker.internal:11434" -ForegroundColor Gray
Write-Host ""
