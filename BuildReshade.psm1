
function Build-ReShade {
    devenv.com .\ReShade.sln /Rebuild "Release|32-bit"
    devenv.com .\ReShade.sln /Rebuild "Release|64-bit"
    devenv.com .\examples\Examples.sln /Rebuild "Release|x86"
    devenv.com .\examples\Examples.sln /Rebuild "Release|x64"
}

function Install-ReShade {
    New-Item .\bin_output -ItemType Directory
    New-Item .\bin_output\x86 -ItemType Directory
    New-Item .\bin_output\x64 -ItemType Directory
    
    Copy-Item -Path ".\bin\Win32\Release\*.exe" -Destination ".\bin_output\x86"
    Copy-Item -Path ".\bin\Win32\Release\*.dll" -Destination ".\bin_output\x86"
    Copy-Item -Path ".\bin\Win32\Release Examples\*.addon*" -Destination ".\bin_output\x86"
    
    Copy-Item -Path ".\bin\x64\Release\*.exe" -Destination ".\bin_output\x64"
    Copy-Item -Path ".\bin\x64\Release\*.dll" -Destination ".\bin_output\x64"
    Copy-Item -Path ".\bin\x64\Release Examples\*.addon*" -Destination ".\bin_output\x64"
}

Export-ModuleMember -Function Build-ReShade, Install-ReShade