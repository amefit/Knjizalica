# Knjizalica API smoke test
$ErrorActionPreference = "Stop"
$base = "http://localhost:5000"
$failed = 0

function Test-Endpoint {
    param($Name, $ScriptBlock)
    try {
        & $ScriptBlock
        Write-Host "[OK] $Name" -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] $Name - $($_.Exception.Message)" -ForegroundColor Red
        $script:failed++
    }
}

Write-Host "Knjizalica API smoke tests -> $base`n"

Test-Endpoint "Auth login (admin)" {
    $script:adminLogin = Invoke-RestMethod -Uri "$base/api/auth/login" -Method POST -ContentType "application/json" -Body '{"username":"desktop","password":"test"}'
    $script:adminHeaders = @{ Authorization = "Bearer $($script:adminLogin.token)" }
}

Test-Endpoint "Auth login (member)" {
    $script:memberLogin = Invoke-RestMethod -Uri "$base/api/auth/login" -Method POST -ContentType "application/json" -Body '{"username":"mobile","password":"test"}'
    $script:memberHeaders = @{ Authorization = "Bearer $($script:memberLogin.token)" }
}

Test-Endpoint "Dashboard" {
    $d = Invoke-RestMethod -Uri "$base/api/dashboard" -Headers $script:adminHeaders
    if ($null -eq $d.kpis) { throw "Missing kpis" }
}

Test-Endpoint "Books list" {
    $b = Invoke-RestMethod -Uri "$base/api/books?page=1&pageSize=5" -Headers $script:adminHeaders
    if ($b.totalCount -lt 1) { throw "No books" }
}

Test-Endpoint "Authors list" {
    Invoke-RestMethod -Uri "$base/api/authors?page=1&pageSize=5" -Headers $script:adminHeaders | Out-Null
}

Test-Endpoint "Members list" {
    Invoke-RestMethod -Uri "$base/api/members?page=1&pageSize=5" -Headers $script:adminHeaders | Out-Null
}

Test-Endpoint "Loans list" {
    Invoke-RestMethod -Uri "$base/api/loans?page=1&pageSize=5" -Headers $script:adminHeaders | Out-Null
}

Test-Endpoint "Loans my (member)" {
    Invoke-RestMethod -Uri "$base/api/loans/my?page=1&pageSize=5" -Headers $script:memberHeaders | Out-Null
}

Test-Endpoint "Loans overdue" {
    Invoke-RestMethod -Uri "$base/api/loans/overdue?page=1&pageSize=5" -Headers $script:adminHeaders | Out-Null
}

Test-Endpoint "Reservations availability" {
    $books = Invoke-RestMethod -Uri "$base/api/books/1" -Headers $script:memberHeaders
    $copyId = $books.copies[0].id
    $from = [Uri]::EscapeDataString((Get-Date).ToUniversalTime().ToString("o"))
    $to = [Uri]::EscapeDataString((Get-Date).AddDays(14).ToUniversalTime().ToString("o"))
    Invoke-RestMethod -Uri "$base/api/reservations/availability/${copyId}?fromDate=$from&toDate=$to" -Headers $script:memberHeaders | Out-Null
}

Test-Endpoint "Recommendations" {
    $r = Invoke-RestMethod -Uri "$base/api/recommendations?limit=5" -Headers $script:memberHeaders
    if ($null -eq $r.contentBased) { throw "Missing contentBased" }
}

Test-Endpoint "Notifications" {
    Invoke-RestMethod -Uri "$base/api/notifications?page=1&pageSize=5" -Headers $script:memberHeaders | Out-Null
}

Test-Endpoint "News public" {
    Invoke-RestMethod -Uri "$base/api/news/public" | Out-Null
}

Test-Endpoint "Reference data cities (anonymous)" {
    Invoke-RestMethod -Uri "$base/api/referencedata/cities" | Out-Null
}

Test-Endpoint "Activity logs" {
    Invoke-RestMethod -Uri "$base/api/activitylogs?page=1&pageSize=5" -Headers $script:adminHeaders | Out-Null
}

Test-Endpoint "Report overdue PDF" {
    # UseBasicParsing avoids IE-based handlers that hang on binary PDF responses.
    $pdf = Invoke-WebRequest -Uri "$base/api/reports/overdue-loans" -Headers $script:adminHeaders -UseBasicParsing -TimeoutSec 30
    if ($pdf.Headers["Content-Type"] -notlike "*pdf*") { throw "Not PDF" }
    if ($pdf.RawContentLength -lt 100) { throw "PDF too small" }
}

Test-Endpoint "Report loans by period PDF" {
    $from = [Uri]::EscapeDataString((Get-Date).AddMonths(-1).ToString("yyyy-MM-dd"))
    $to = [Uri]::EscapeDataString((Get-Date).ToString("yyyy-MM-dd"))
    $r = Invoke-WebRequest -Uri "$base/api/reports/loans-by-period?fromDate=$from&toDate=$to" -Headers $script:adminHeaders -UseBasicParsing -TimeoutSec 30
    if ($r.Headers["Content-Type"] -notlike "*pdf*") { throw "Not PDF" }
}

Write-Host "`nDone. Failed: $failed"
if ($failed -gt 0) { exit 1 }
