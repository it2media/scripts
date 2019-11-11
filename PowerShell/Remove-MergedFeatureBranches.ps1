param(
[string]$gitFolder)
$currentDir = Get-Location
cd $gitFolder
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
