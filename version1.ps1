Add-Type -Assemblyname System.Windows.Forms

function Create-Form ([string]$name, $x, $y, $w, $h) {
    $win = New-Object System.Windows.Forms.Form
    $win.StartPosition = "Manual"
    $win.Location = New-Object System.Drawing.Size($x, $y)
    $win.Width = $w
    $win.Height = $h
    $win.Text = $name
    $win.Topmost = $True
    $win
}

function Create-Label ([string]$name, $x, $y) {
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point($x, $y)
    $label.Text = $name
    $label.AutoSize = $true
    $label
}

function Create-Button ([string]$name, $x, $y, $w, $h) {
    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point($x, $y)
    $button.Size = New-Object System.Drawing.Size($w, $h)
    $button.Text = $name
    $button.Enabled = $false
    $button
}

function Start-Scroll () {
    $form = Create-Form "Let's GO!" 200 150 300 400
    $start = Create-Label "Press SPACE to run" 90 200
    $info = Create-Label "<-- A   D -->    'Esc' for exit" 80 340
    $ship = Create-Label "/|\" 135 400
    $form.Controls.Add($start)
    $form.Controls.Add($info)
    $form.Controls.Add($ship)
    $Data = @{run = $false; hide = $false; pos = 135; shot = 0; spawn = 0; usb = 0; score = 0; fires = @(); enemies = @() }
    $form.KeyPreview = $True
    $form.Add_KeyDown({
            if ($_.KeyCode -eq "A") { if ($Data.run -and -not $Data.hide -and $Data.pos -gt 0) { $Data.pos -= 5 } }
        })
    $form.Add_KeyDown({
            if ($_.KeyCode -eq "D") { if ($Data.run -and -not $Data.hide -and $Data.pos -lt 265) { $Data.pos += 5 } }
        })    
    $form.Add_KeyDown({
            if ($_.KeyCode -eq "Escape") { $timer.stop(); $form.Close() }
        })    
    $form.Add_KeyDown({
            if ($_.KeyCode -eq "Space") {
                if ($Data.run) { Set-Hide }
                else { $start.Text = ""; $Data.run = $true }
            }
        })

    $sound = new-Object System.Media.SoundPlayer;
    $sound.SoundLocation = "$env:WINDIR\Media\Windows Information Bar.wav"
    $form.ShowDialog()
}
function Set-Hide () {
    if ($Data.hide) {
        $start.Text = ""
        $start.Location = New-Object System.Drawing.Point(90, 200)
        $Data.enemies | foreach { $_.obj.Visible = $true }
        $Data.fires | foreach { $_.obj.Visible = $true }
        $info.Visible = $true
        $ship.Visible = $true
    }
    else {
        $start.Location = New-Object System.Drawing.Point(10, 10)
        $Data.enemies | foreach { $_.obj.Visible = $false }
        $Data.fires | foreach { $_.obj.Visible = $false }
        $info.Visible = $false
        $ship.Visible = $false
    }
    $Data.hide = -not $Data.hide
}
function Check () {
    # Если игра не запущена - ничего не делаем
    if (!$Data.run) { return }
    # Если пауза - выводим сторонний текст
    if ($Data.hide) {
        if ($Data.usb -eq 0) {
            $start.Text = ""
            gwmi Win32_USBControllerDevice | % { [wmi]($_.Dependent) } | where { $_.DeviceID -notlike '*ROOT_HUB*' } | Sort Description | foreach { $start.Text += $_.Description + "`n" }
            $Data.usb = 500
        }
        else { $Data.usb -= 1 }
        return
    }
    # Обновляем положение игрока
    $ship.Location = New-Object System.Drawing.Point($Data.pos, 300)
    # Создаем снаряд, если пришло время
    if ($Data.shot -eq 0) {
        $Data.fires += @{ obj = Create-Label "*" ($Data.pos + 5) 290; x = $Data.pos + 5; y = 290 }
        $form.Controls.Add($Data.fires[$Data.fires.Length - 1].obj)
        $Data.shot = 4
    }
    else { $Data.shot -= 1 }
    # Создаем противника, если пришло время
    if ($Data.spawn -eq 0) {
        $hp = Get-Random -minimum 4 -maximum 6
        $pos = Get-Random -minimum 0 -maximum 200
        $Data.enemies += @{ obj = Create-Button "$hp" $pos -22 30 20; x = $pos; y = -22; health = $hp }
        $form.Controls.Add($Data.enemies[$Data.enemies.Length - 1].obj)
        $Data.spawn = 150 * $Data.enemies.Length
    }
    else { $Data.spawn -= 1 }
    # Проверяем снаряды
    foreach ($fire in $Data.fires) {
        # Обновляем положение
        $fire.obj.Location = New-Object System.Drawing.Point($fire.x, $fire.y)
        $fire.y -= 5
        # Проверяем для каждого снаряда/противника - нет ли столкновения
        foreach ($enemy in $Data.enemies) {
            if ($fire.x + 5 -gt $enemy.x -and $fire.x -lt $enemy.x + 25 -and $fire.y -gt $enemy.y -and $fire.y -lt $enemy.y + 20) {
                $enemy.health -= 1
                $enemy.obj.Text = $enemy.health
                $fire.y = -20
                $sound.Play()
            }
        }
    }
    # Если первый в списке снаряд вышел за экран - убираем его
    if ($Data.fires[0].y -lt -10) {
        $form.Controls.Remove($Data.fires[0].obj)
        $Data.fires = $Data.fires[1..($Data.fires.Length - 1)]
    }
    # Проверяем противников
    foreach ($enemy in $Data.enemies) {
        # Если убит - перезапускаем
        if ($enemy.health -gt 0) { $enemy.y += 1 } else {
            $Data.score += 1
            $enemy.health = Get-Random -minimum 4 -maximum 6
            $enemy.x = Get-Random -minimum 1 -maximum 200
            $enemy.y = -22
            $enemy.obj.Text = $enemy.health
        }
        # Обновляем положение
        $enemy.obj.Location = New-Object System.Drawing.Point($enemy.x, $enemy.y)
        # Если приземлился - останавливаем игру
        if ($enemy.y -gt 300) {
            $Data.run = $false
            $start.Text = "Total score: " + $Data.score
        }
    }
}

$timer = New-Object system.windows.forms.timer
    $timer.Interval = 100
    $timer.add_tick({Check})
    $timer.start()

Start-Scroll