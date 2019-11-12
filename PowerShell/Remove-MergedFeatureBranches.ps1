param(
[string]$gitFolder)
$OutputEncoding = New-Object -typename System.Text.UTF8Encoding
[Console]::OutputEncoding = New-Object -typename System.Text.UTF8Encoding
$currentDir = Get-Location
cd $gitFolder
Write-Host "git branch -r --merged develop"
git branch -r --merged develop
Write-Host "Deleting */feature/ branches:"
git branch -r --merged develop | Out-File -FilePath "tools/deleted-branches.txt"
$mergedRemoteBranches = git branch -r --merged develop
foreach($mergedRemoteBranch in $mergedRemoteBranches) {
    $remoteBranch = $mergedRemoteBranch.Trim()

    $remoteName = ($remoteBranch -split '/')[0]
    $remoteBranchName = $remoteBranch.Substring($remoteName.Length+1)
    
    if ($remoteBranchName.StartsWith("feature/")) {
        # Write-Host $remoteName
        Write-Host $remoteBranchName
        git push $remoteName --delete $remoteBranchName
    }
}
git fetch --prune
cd $currentDir
