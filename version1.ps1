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

    $form.ShowDialog()
}