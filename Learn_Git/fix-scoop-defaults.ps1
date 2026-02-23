# 修复 Scoop 应用的默认程序关联
param(
    [switch]$AllUsers = $false
)

$ErrorActionPreference = "Stop"

# 获取 Scoop 安装路径
$scoopPath = if ($AllUsers) {
    "$env:ProgramData\scoop"
} else {
    "$env:USERPROFILE\scoop"
}

function Fix-AppAssociation {
    param(
        [string]$AppName,
        [string]$ExeName,
        [array]$FileTypes
    )
    
    $appPath = Join-Path $scoopPath "apps\$AppName\current\$ExeName"
    
    if (Test-Path $appPath) {
        foreach ($ext in $FileTypes) {
            # 设置文件关联
            cmd /c "assoc $ext=$AppName"
            cmd /c "ftype $AppName=\"$appPath\" \"%1\""
            
            Write-Host "已关联 $ext 到 $AppName" -ForegroundColor Green
        }
    }
}

# 示例：为常用应用设置关联
$appAssociations = @{
    "7zip" = @{
        Exe = "7zFM.exe"
        Exts = @(".zip", ".7z", ".rar", ".tar", ".gz")
    }
    "draw.io" = @{
        Exe = "draw.io.exe"
        Exts = @(".drawio", ".dio")
    }
    "gimp" = @{
        Exe = "bin\gimp-3.0.exe"
        Exts = @(".xcf", ".psd", ".jpg", ".png")
    }
    "vlc" = @{
        Exe = "vlc.exe"
        Exts = @(".mp4", ".avi", ".mkv", ".mp3", ".flac")
    }
    "libreoffice" = @{
        Exe = "program\soffice.exe"
        Exts = @(".odt", ".ods", ".odp", ".docx", ".xlsx")
    }
}

foreach ($app in $appAssociations.Keys) {
    Fix-AppAssociation -AppName $app `
        -ExeName $appAssociations[$app].Exe `
        -FileTypes $appAssociations[$app].Exts
}