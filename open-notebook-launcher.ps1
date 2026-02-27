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

    # Docker Desktop の実行ファイルを探す
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

    # Docker が使えるようになるまでポーリング
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
            # 2分でタイムアウト
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

    # タイマーでジョブ完了を監視
    $script:startTimer = New-Object System.Windows.Forms.Timer
    $script:startTimer.Interval = 1000
    $script:startTimer.Add_Tick({
        if ($script:startJob.State -eq "Completed" -or $script:startJob.State -eq "Failed") {
            $script:startTimer.Stop()
            $script:startTimer.Dispose()

            # 15秒待ってからステータス更新
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
            "Docker Desktop が起動していません。`n先に Docker Desktop を起動してください。",
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
