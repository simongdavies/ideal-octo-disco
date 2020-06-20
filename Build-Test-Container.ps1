[CmdletBinding()]
param (
  [Parameter(Mandatory=$false)] 
  [string]
  $TestSourceLocation="C:\dev\AzureUX\AZSaaS\src\tests",
  [Parameter(Mandatory=$false)] 
  [string]
  $DockerFile=".\Dockerfile.local.test",
  [Parameter(Mandatory=$false)] 
  [string]
  $LinuxTestRunScript=".\run_tests_in_container.sh",
  [Parameter(Mandatory=$false)] 
  [string]
  $Tag="rpaas:test",
  [Parameter(Mandatory=$false)] 
  [string]
  $OutputFolder="${env:LOCALAPPDATA}\rpaas",
  [Parameter(Mandatory=$false)] 
  [string]
  $CertPFX="emulator.pfx",
  [Parameter(Mandatory=$false)] 
  [string]
  $CertPwd="",
  [Parameter(Mandatory=$false)] 
  [string[]]
  [ValidateScript({$_|ForEach-Object{($(${_}).ToLower() -eq "controller") -or ($(${_}).ToLower() -eq "common") -or ($(${_}).ToLower() -eq "data")}})]
  $Projects=@("controller","common","data"),
  [Parameter(Mandatory=$false)] 
  [switch]
  $DoNotBuild=$false
)
mkdir -p ${OutputFolder} -ErrorAction SilentlyContinue
if (${TestSourceLocation} -ne ${PWD}) {
  Push-Location -Path ${TestSourceLocation} -StackName test_in_linux_container
}
try {
  if (!${DoNotBuild}) {
    foreach ($Project in $Projects) {
      dotnet build "./tests.${Project}/tests.${Project}.csproj" -c Release -o ${OutputFolder}/tests.${Project}
      copy-item "./tests.${Project}/tests.${Project}.csproj" "${OutputFolder}/tests.${Project}/tests.${Project}.csproj" -force
    }
  }

  copy-item $(Join-Path $PSScriptRoot ${LinuxTestRunScript}) ${OutputFolder} -force
  copy-item $(Join-Path  $PSScriptRoot ${CertPFX}) ${OutputFolder} -force
  $commandArgs=('build','--pull','-t',"${Tag}",'-f',"$(Join-Path  $PSScriptRoot ${Dockerfile})",'--build-arg',"certpwd=${CertPwd}",'--build-arg',"certfile=${CertPFX}",${OutputFolder})
  docker @commandArgs
}
finally {
  Pop-Location -StackName test_in_linux_container -ErrorAction SilentlyContinue
}