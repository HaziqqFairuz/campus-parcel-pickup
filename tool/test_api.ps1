param([string]$Php = 'php', [int]$Port = 8791)

$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$public = Join-Path $project 'backend/public'
$private = Join-Path $project 'backend/private'
$phpExe = (Get-Command $Php -CommandType Application).Source
$temporary = Join-Path ([System.IO.Path]::GetTempPath()) ('parcel-test-' + [Guid]::NewGuid())
New-Item -ItemType Directory -Path $temporary | Out-Null
$oldDb = $env:PARCEL_DB_PATH
$oldPassword = $env:PARCEL_OPERATOR_PASSWORD
$env:PARCEL_DB_PATH = Join-Path $temporary 'test.sqlite'
$env:PARCEL_OPERATOR_PASSWORD = [Guid]::NewGuid().ToString()
$base = "http://127.0.0.1:$Port"
$server = $null

function Invoke-Api($Method, $Name, $Form, $Token, [int]$Expected) {
    $params = @{
        Uri = "$base/$Name"
        Method = $Method
        SkipHttpErrorCheck = $true
        TimeoutSec = 5
    }
    if ($null -ne $Form) { $params.Body = $Form }
    if ($Token) { $params.Headers = @{ Authorization = "Bearer $Token" } }
    $response = Invoke-WebRequest @params
    if ($response.StatusCode -ne $Expected) {
        throw "$Name returned HTTP $($response.StatusCode), expected $Expected. $($response.Content)"
    }
    $json = $response.Content | ConvertFrom-Json
    if ($json.success -ne ($Expected -lt 400)) { throw "Unexpected success flag from $Name" }
    return $json
}

try {
    & $phpExe (Join-Path $private 'create_operator.php') 'Test Operator' 'operator@example.test'
    if ($LASTEXITCODE -ne 0) { throw 'Operator seed failed' }
    $server = Start-Process -FilePath $phpExe -WorkingDirectory $public -ArgumentList '-S', "127.0.0.1:$Port", '-t', '.' -WindowStyle Hidden -PassThru -RedirectStandardError (Join-Path $temporary 'php.log')
    for ($retry = 0; $retry -lt 20; $retry++) {
        if ($server.HasExited) { throw 'Test PHP server failed to start' }
        try {
            Invoke-Api GET 'profile.php' $null $null 401 | Out-Null
            break
        } catch [System.Net.Http.HttpRequestException] {
            Start-Sleep -Milliseconds 150
        }
    }

    $password = [Guid]::NewGuid().ToString()
    $form = @{
        name = 'Test Recipient'
        email = 'recipient@example.test'
        password = $password
        confirm_password = $password
        role = 'parcel_operator'
    }
    Invoke-Api POST 'register.php' $form $null 201 | Out-Null
    Write-Host 'PASS 1 valid registration'
    $duplicate = $form.Clone()
    $duplicate.email = 'RECIPIENT@example.test'
    Invoke-Api POST 'register.php' $duplicate $null 409 | Out-Null
    Write-Host 'PASS 2 duplicate email rejected case-insensitively'
    $invalid = $form.Clone()
    $invalid.confirm_password = 'Different123'
    Invoke-Api POST 'register.php' $invalid $null 422 | Out-Null
    $invalid.email = 'bad-address'
    Invoke-Api POST 'register.php' $invalid $null 422 | Out-Null
    $invalid.name = ''
    Invoke-Api POST 'register.php' $invalid $null 422 | Out-Null
    Write-Host 'PASS 3 invalid registration rejected'

    $credentials = @{ email = $form.email; password = $password }
    $recipient = Invoke-Api POST 'login.php' $credentials $null 200
    $profile = Invoke-Api GET 'profile.php' $null $recipient.token 200
    if ($profile.user.name -ne $form.name -or $profile.user.email -ne $form.email) { throw 'Wrong recipient profile' }
    Write-Host 'PASS 4 correct credentials return a session and profile'
    Invoke-Api POST 'login.php' @{ email = $form.email; password = 'Wrong123' } $null 401 | Out-Null
    Write-Host 'PASS 5 incorrect credentials rejected'
    $operator = Invoke-Api POST 'login.php' @{ email = 'operator@example.test'; password = $env:PARCEL_OPERATOR_PASSWORD } $null 200
    $operatorProfile = Invoke-Api GET 'profile.php' $null $operator.token 200
    if ($profile.user.role -ne 'recipient' -or $operatorProfile.user.role -ne 'parcel_operator') { throw 'Wrong server-assigned roles' }
    Write-Host 'PASS 6 both roles returned, public role override ignored'
    Invoke-Api GET 'profile.php' $null $recipient.token 200 | Out-Null
    Write-Host 'PASS 7 API accepts the previously issued session on a separate request'
    Invoke-Api GET 'profile.php' $null $null 401 | Out-Null
    Write-Host 'PASS 8 anonymous profile denied'
    Invoke-Api POST 'logout.php' $null $recipient.token 200 | Out-Null
    Invoke-Api GET 'profile.php' $null $recipient.token 401 | Out-Null
    Invoke-Api POST 'logout.php' $null $recipient.token 200 | Out-Null
    Invoke-Api GET 'profile.php' $null $operator.token 200 | Out-Null
    Write-Host 'PASS 9 revoked token rejected and other session preserved'

    $privateResponse = Invoke-WebRequest -Uri "$base/parcel.sqlite" -SkipHttpErrorCheck -TimeoutSec 5
    if ($privateResponse.StatusCode -ne 404) { throw 'Database was reachable from the web root' }
    Write-Host 'PASS database outside web root'
} finally {
    if ($server -and !$server.HasExited) {
        Stop-Process -Id $server.Id
        $server.WaitForExit()
    }
    $env:PARCEL_DB_PATH = $oldDb
    $env:PARCEL_OPERATOR_PASSWORD = $oldPassword
    foreach ($name in 'test.sqlite', 'test.sqlite-shm', 'test.sqlite-wal', 'test.sqlite-journal', 'php.log') {
        $path = Join-Path $temporary $name
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path }
    }
    Remove-Item -LiteralPath $temporary
}

