# Load Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# Define the base path
$basePath = "$env:LOCALAPPDATA\Stormgate\Saved\Replays"
$downloadsPath = "$env:USERPROFILE\Downloads"

# Identify the random-named parent folder, doesnt support multiple Steam accs
$randomFolder = Get-ChildItem -Path $basePath | Where-Object { $_.PSIsContainer } | Select-Object -First 1

# If the folder is found, set the full path, else crash out
if ($randomFolder) {
    $path = Join-Path -Path $basePath -ChildPath $randomFolder.Name
} else {
    [System.Windows.Forms.MessageBox]::Show("No random-named folder found in the specified path.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}

$script:numberOfFiles = 5

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Stormgate Replay Manager"
$form.Size = New-Object System.Drawing.Size(600, 450)

# Create the ListView to display files
$listView = New-Object System.Windows.Forms.ListView
$listView.View = 'Details'
$listView.FullRowSelect = $true
$listView.Width = 550
$listView.Height = 250
$listView.Location = New-Object System.Drawing.Point(20, 20)

# Add columns
$listView.Columns.Add("Replay Name", 400)
$listView.Columns.Add("Replay Time", 150)

# Function to load files into the ListView
function Load-Files {
    param (
        [int]$numberOfFiles
    )
    $listView.Items.Clear()  # Explicitly clear items

    # Load the files into the ListView
    $files = Get-ChildItem -Path $path | Sort-Object LastWriteTime -Descending | Select-Object -First $numberOfFiles

    foreach ($file in $files) {
        $item = New-Object System.Windows.Forms.ListViewItem($file.Name)
        $item.SubItems.Add($file.LastWriteTime.ToString())
        $item.Tag = $file.FullName
        $listView.Items.Add($item)
    }

    $listView.Refresh()
}

# Function to check the Downloads folder
function Check-Downloads {
    # Check the last 50 files in Downloads for .SGReplay files
    $recentFiles = Get-ChildItem -Path $downloadsPath | Sort-Object LastWriteTime -Descending | Select-Object -First 50
    $sgReplayFiles = $recentFiles | Where-Object { $_.Extension -eq ".SGReplay" }

    foreach ($file in $sgReplayFiles) {
        $destination = Join-Path -Path $path -ChildPath $file.Name
        Copy-Item -Path $file.FullName -Destination $destination -Force
    }
    
    $listView.Items.Clear()  # Explicitly clear items

    # Load the files into the ListView
    $files = Get-ChildItem -Path $path | Sort-Object LastWriteTime -Descending | Select-Object -First $numberOfFiles

    foreach ($file in $files) {
        $item = New-Object System.Windows.Forms.ListViewItem($file.Name)
        $item.SubItems.Add($file.LastWriteTime.ToString())
        $item.Tag = $file.FullName
        $listView.Items.Add($item)
    }

    $listView.Refresh()


}

# Initial load
Load-Files -numberOfFiles $script:numberOfFiles
$form.Controls.Add($listView)

# Rename Button
$renameButton = New-Object System.Windows.Forms.Button
$renameButton.Text = "Rename"
$renameButton.Width = 80
$renameButton.Height = 30
$renameButton.Location = New-Object System.Drawing.Point(240, 280)
$renameButton.Add_Click({
    $selectedItem = $listView.SelectedItems[0]
    if ($selectedItem) {
        $oldName = $selectedItem.Text
        $oldPath = $selectedItem.Tag
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($oldName)  # Extract the name without extension

        # Prompt for new name
        $newNamePrompt = New-Object System.Windows.Forms.Form
        $newNamePrompt.Text = "Rename File"
        $newNamePrompt.Size = New-Object System.Drawing.Size(300, 150)

        $inputBox = New-Object System.Windows.Forms.TextBox
        $inputBox.Size = New-Object System.Drawing.Size(200, 20)
        $inputBox.Location = New-Object System.Drawing.Point(50, 20)
        $inputBox.Text = $baseName
        $newNamePrompt.Controls.Add($inputBox)

        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Text = "OK"
        $okButton.Location = New-Object System.Drawing.Point(50, 50)
        $okButton.Add_Click({
            $newName = $inputBox.Text
            if ($newName -ne $null -and $newName -ne "") {
                $newNameWithExtension = "$newName.SGReplay"
                $newPath = Join-Path -Path (Split-Path -Path $oldPath) -ChildPath $newNameWithExtension
                Rename-Item -Path $oldPath -NewName $newNameWithExtension

                # Update ListView
                $selectedItem.Text = $newNameWithExtension
                $newNamePrompt.Close()
            }
        })
        $newNamePrompt.Controls.Add($okButton)

        # Handle Enter key for closing and confirming
        $newNamePrompt.KeyPreview = $true
        $newNamePrompt.Add_KeyDown({
            if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                $okButton.PerformClick()
            }
        })

        [void]$newNamePrompt.ShowDialog()
    }
})
$form.Controls.Add($renameButton)

# Button to show more files
$moreButton = New-Object System.Windows.Forms.Button
$moreButton.Text = "Show 5 More"
$moreButton.Width = 100
$moreButton.Height = 30
$moreButton.Location = New-Object System.Drawing.Point(60, 280)

$moreButton.Add_Click({
    $script:numberOfFiles += 5
    Load-Files -numberOfFiles $script:numberOfFiles
})
$form.Controls.Add($moreButton)

# Button to show fewer files
$lessButton = New-Object System.Windows.Forms.Button
$lessButton.Text = "Show 5 Less"
$lessButton.Width = 100
$lessButton.Height = 30
$lessButton.Location = New-Object System.Drawing.Point(400, 280)

$lessButton.Add_Click({
    if ($script:numberOfFiles -gt 5) {
        $script:numberOfFiles -= 5
        Load-Files -numberOfFiles $script:numberOfFiles
    }
})
$form.Controls.Add($lessButton)

# Button to check downloads
$toggleWatcherButton = New-Object System.Windows.Forms.Button
$toggleWatcherButton.Text = "Check Downloads"
$toggleWatcherButton.Width = 150
$toggleWatcherButton.Height = 30
$toggleWatcherButton.Location = New-Object System.Drawing.Point(200, 330)

$toggleWatcherButton.Add_Click({
    Check-Downloads
})
$form.Controls.Add($toggleWatcherButton)

# Refresh Button
$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = "Refresh"
$refreshButton.Width = 150
$refreshButton.Height = 30
$refreshButton.Location = New-Object System.Drawing.Point(200, 370)

$refreshButton.Add_Click({
    Load-Files -numberOfFiles $script:numberOfFiles
})

$form.Controls.Add($refreshButton)

# Help Button
$helpButton = New-Object System.Windows.Forms.Button
$helpButton.Text = "Help"
$helpButton.Width = 80
$helpButton.Height = 30
$helpButton.Location = New-Object System.Drawing.Point(480, 370)

# Add Click event to display a message box when the help button is clicked
$helpButton.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("This tool allows you to rename replays and move replays from your Downloads folder into the Stormgate client. The default file paths it uses are `$env:LOCALAPPDATA\Stormgate\Saved\Replays` for Replays, and `c:\users\<username>\downloads` for Downloads.", "Help", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})
$form.Controls.Add($helpButton)

Clear-Host

# Show the form
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
