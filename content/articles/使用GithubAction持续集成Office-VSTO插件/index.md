---
title: 使用GithubAction持续集成Office-VSTO插件
description: 使用Windows Installer 部署Office VSTO插件并配置Github Action以进行持续集成。
tags:
- csharp
- office add-ins
- github action
categories:
- tutorials
date: '2025-09-06'
withToc: true
cover: 'images/cover.png'
keepOrigin: false
typst: false
noWordTime: false
katex: false
---
> 图片来源于 : [Unsplash](https://unsplash.com/)
# Overview

Office插件是通常用于为Office应用程序提供功能扩展，以PowerPoint为例，Microsoft在[PowerPoint add-ins quick start](https://learn.microsoft.com/en-us/office/dev/add-ins/quickstarts/powerpoint-quickstart-content#explore-the-visual-studio-solution)中列出了两种常见的插件形式，`Add-in project`(使用C#或者VB)与`Web application project`(使用HTML+JS+CSS)，还有一种尚未列出的为使用PowerPoint内置脚本编辑器产生的`.pptm`宏。

本文面对的对象为适用于PowerPoint，使用`Add-in project`方案的插件。`Add-in project`通常会使用`ClickOnce`打包，生成VSTO文件。这个方案依赖于Windows的COM机制，因此其只能在Windows上使用。但是其与原生的.NET / WPF / Windows Form开发流程十分接近，较为方便上手的同时，得益于Visual Studio本身对于.NET类项目的优秀支持，有着完整且便利的开发流程。

由于本文主要关心VSTO插件的打包与持续集成，并不会涉及到Step-by-Step的教程可以从[这里](https://learn.microsoft.com/en-us/visualstudio/vsto/walkthrough-creating-your-first-vsto-add-in-for-powerpoint?view=vs-2022&tabs=csharp)获取，如果不认为C#是一个好的选择，那么使用web application[教程看这里](https://learn.microsoft.com/en-us/office/dev/add-ins/quickstarts/powerpoint-quickstart-vs)可能更符合你的需求🤗。

# 使用Windows Installer部署Office VSTO插件

在已有的插件解决方案下，创建Windows Setup Project，按照[此处](https://learn.microsoft.com/en-us/visualstudio/vsto/deploying-a-vsto-solution-by-using-windows-installer?view=vs-2022)配置即可


# 使用GitHub Action进行持续集成

关于如何使用Github Action对VSTO插件进行持续集成，在StackOverFlow已有相关较为完善的方案[此处](https://stackoverflow.com/questions/71823928/build-installer-using-github-actions#:~:text=Yes%2C%20it%20is%20possible.)与解决`ERROR: An error occurred while validating.  HRESULT = '8000000A'`的方案[此处](https://stackoverflow.com/questions/71823928/build-installer-using-github-actions#:~:text=Thanks%20to%20the%20information%20provided%20in%20this%20link%20Building%20VDProj%20I%20have%20copied%20the%20suggested)，在本段后面，我们将会给补充证书签名相关的问题，并在[后文](#examples)给出一份较为完善的示例代码。

由于ClickOnce的限制，VSTO插件需要签名才能编译，但幸运的是，Microsoft似乎不会校验证书是否来自于可信机构，因此我们只需要自签名证书就可以了。使用以下的PowerShell代码创建证书后
```powershell
New-SelfSignedCertificate -Subject 'CN=Description of Certificate' -Type CodeSigning -KeyUsage DigitalSignature -FriendlyName 'Name' -CertStoreLocation Cert:\CurrentUser\My -HashAlgorithm SHA256 -NotAfter (Get-Date).AddYears(2)
```
使用下面给出的PowerShell代码
```powershell
$securePassword = ConvertTo-SecureString -String 'Some Password' -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath 'path.pfx' -Password $securePassword
```
将创建的证书导出为由指定密码保护的pfx证书文件。由于pfx证书有密码保护，可以放心的上传至远程仓库，将密码保存至Github secrets。但为了安全起见，可以将证书进行base64处理后同样上传至Github secrets，可以使用如下代码：
```powershell
$certPath = "path of pfx.pfx"
$certBytes = [System.IO.File]::ReadAllBytes($certPath)
$base64String = [System.Convert]::ToBase64String($certBytes)
Write-Output $base64String
```
从Github secrets复原证书到action工作目录并导入CurrentUser\My可以参考示例中的`Import Certificate`部分。

{{% hint Info "注意"%}}
VisualStudio在开发时会使用自己的证书，你应该更改项目属性的签名tab下的签名证书为你生成的证书，并且检查`.csproj`下的`&ltManifestCertificateThumbprint>`的值是否为你证书的指纹，未修改的设置可能会导致在Action编译时报`error MSB3326`与`error MSB3321`。
{{% /hint %}}

另外，[此处](https://github.com/zentialEdwardSu/ppmeta/blob/master/.github/workflows/setup-certificate.nu)提供了一个AI编写的Nushell脚本用于快速生成关于证书的一切👆🤓。

# Examples

本示例提供了一个较为完整的示例，有以下假设：

1. 通过`VSTO_CERTIFICATE`设置了Base64加密的pfx证书
2. 通过`VSTO_CERT_PASSWORD`设置了证书对应的密码
3. VSTO项目位于`ppmeta\ppmeta.sln`
4. Setup Installer项目位于`ppSetup\ppSetup.vdproj`

其中包含了较多用于调试的信息，可以减去以让workflow更加简洁。


```yml
name: Simple VSTO Build

on:
  workflow_dispatch:

jobs:
  build:
    runs-on: windows-2022
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup MSBuild
      uses: microsoft/setup-msbuild@v2
      
    - name: Setup VS Dev Environment
      uses: seanmiddleditch/gha-setup-vsdevenv@v4

    - name: DisableOutOfProc Fix
      run: |
        function Invoke-DisableOutOfProcBuild {
            param ();
            $visualStudioWherePath = ('{0}/Microsoft Visual Studio/Installer/vswhere.exe' -f ${Env:ProgramFiles(x86)});
            $visualStudioInstallationPath = & $visualStudioWherePath -latest -products 'Microsoft.VisualStudio.Product.Enterprise' -property 'installationPath';
            $currentWorkingDirectory = ('{0}/Common7/IDE/CommonExtensions/Microsoft/VSI/DisableOutOfProcBuild' -f $visualStudioInstallationPath);
            
            Set-Location -Path $currentWorkingDirectory;
            
            $disableOutOfProcBuildPath = ('{0}/DisableOutOfProcBuild.exe' -f $currentWorkingDirectory);
            
            & $disableOutOfProcBuildPath;
            
            return;
        }
        Invoke-DisableOutOfProcBuild
      
    - name: Import Certificate
      shell: pwsh
      run: |
        $certBytes = [System.Convert]::FromBase64String("${{ secrets.VSTO_CERTIFICATE }}")
        $certPath = "${{ github.workspace }}\ppmeta\ppmeta_TemporaryKey.pfx"
        [System.IO.File]::WriteAllBytes($certPath, $certBytes)
        Write-Host "Certificate file created at: $certPath"
        
        try {
          $certPassword = ConvertTo-SecureString "${{ secrets.VSTO_CERT_PASSWORD }}" -AsPlainText -Force
          
          $cert = Import-PfxCertificate -FilePath $certPath -CertStoreLocation "Cert:\CurrentUser\My" -Password $certPassword -Exportable
          Write-Host "Certificate imported to Personal store with thumbprint: $($cert.Thumbprint)"
          
        } catch {
          Write-Error "Certificate import failed: $($_.Exception.Message)"
          exit 1
        }
        
    - name: Restore packages
      run: nuget restore "${{ github.workspace }}\ppmeta.sln"
        
    - name: Build VSTO
      shell: pwsh
      run: |
        Write-Host "Starting VSTO build..."
        Write-Host "Current directory: $(Get-Location)"
        Write-Host "Workspace: ${{ github.workspace }}"
        
        # Check if certificate file exists
        $certPath = "${{ github.workspace }}\ppmeta\ppmeta_TemporaryKey.pfx"
        if (Test-Path $certPath) {
          Write-Host "Certificate file exists at: $certPath"
        } else {
          Write-Host "Warning: Certificate file not found at: $certPath"
        }
        
        try {
          msbuild "${{ github.workspace }}\ppmeta.sln" -p:Configuration=Release -p:Platform="Any CPU" -p:VisualStudioVersion="17.0" -nologo -verbosity:normal -flp:logfile=build.log
        } catch {
          Write-Error "Build failed: $($_.Exception.Message)"
          if (Test-Path "build.log") {
            Write-Host "Build log contents:"
            Get-Content "build.log" | Write-Host
          }
          exit 1
        }
        
    - name: Build Installer
      shell: pwsh
      run: |
        Write-Host "Building installer..."
        Write-Host "ppSetup project path: ${{ github.workspace }}\ppSetup\ppSetup.vdproj"
        
        if (Test-Path "${{ github.workspace }}\ppSetup\ppSetup.vdproj") {
          Write-Host "ppSetup project file found"
          
          # Use devenv to build the installer project
          devenv.com "${{ github.workspace }}\ppSetup\ppSetup.vdproj" /build "Release"
          
          # Check if build succeeded
          if (Test-Path "${{ github.workspace }}\ppSetup\Release\ppSetup.msi") {
            Write-Host "Installer build succeeded: ppSetup.msi created"
          } else {
            Write-Error "Installer build failed: ppSetup.msi not found"
            exit 1
          }
        } else {
          Write-Error "ppSetup project file not found"
          exit 1
        }

    - name: Upload Results
      uses: actions/upload-artifact@v4
      with:
        name: Installer
        path: ppSetup/Release/
        
    - name: Cleanup
      if: always()
      shell: pwsh
      run: Remove-Item "${{ github.workspace }}\ppmeta\ppmeta_TemporaryKey.pfx" -ErrorAction SilentlyContinue
```
