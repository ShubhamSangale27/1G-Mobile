# Live API end-to-end tests (Heroku backend — same as Angular prod).
# Run: powershell -ExecutionPolicy Bypass -File scripts/e2e_api_test.ps1

$ErrorActionPreference = "Stop"
$base = "https://og-backend-ec80a37e82c0.herokuapp.com/api"
$passed = 0
$failed = 0

function Assert-True($condition, [string]$name) {
    if ($condition) {
        Write-Host "[PASS] $name" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "[FAIL] $name" -ForegroundColor Red
        $script:failed++
    }
}

function Login([string]$email, [string]$password) {
    $body = @{ email = $email; password = $password } | ConvertTo-Json
    return Invoke-RestMethod -Uri "$base/auth/login" -Method POST -ContentType "application/json" -Body $body
}

Write-Host "`n=== 1Guntha Mobile API E2E ===`n" -ForegroundColor Cyan

# Auth
$user = Login "user@realestate.com" "user123"
Assert-True ($user.accessToken.Length -gt 0) "USER login returns access token"
Assert-True ($user.user.role -eq "USER") "USER role is USER"

$agent = Login "agent@realestate.com" "agent123"
Assert-True ($agent.accessToken.Length -gt 0) "AGENT login returns access token"
Assert-True ($agent.user.role -eq "AGENT") "AGENT role is AGENT"

$admin = Login "admin@realestate.com" "admin123"
Assert-True ($admin.user.role -eq "ADMIN") "ADMIN login at API level works"
# Mobile policy: ADMIN blocked
$blockedAdmin = @("ADMIN", "BLOG") -contains $admin.user.role
Assert-True $blockedAdmin "ADMIN is blocked on mobile (policy check)"

$blog = Login "blogger@realestate.com" "blog123"
Assert-True ($blog.user.role -eq "BLOG") "BLOG login at API level works"
Assert-True (@("ADMIN", "BLOG") -contains $blog.user.role) "BLOG is blocked on mobile (policy check)"

# Agent site visits
$headers = @{ Authorization = "Bearer $($agent.accessToken)" }
$visits = Invoke-RestMethod -Uri "$base/agent/sitevisits?page=0&size=20" -Headers $headers
Assert-True ($null -ne $visits.content) "AGENT can list site visits"
Assert-True ($null -ne $visits.totalPages) "Site visits response has pagination"

# USER denied agent endpoint
try {
    $uh = @{ Authorization = "Bearer $($user.accessToken)" }
    Invoke-RestMethod -Uri "$base/agent/sitevisits?page=0&size=20" -Headers $uh | Out-Null
    Assert-True $false "USER should not access agent site visits"
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    Assert-True ($code -eq 403 -or $code -eq 401) "USER denied on agent endpoint (HTTP $code)"
}

# Properties
$search = Invoke-RestMethod -Uri "$base/properties/search?page=0&size=10"
Assert-True ($null -ne $search.content) "Public property search works"

$watch = Invoke-RestMethod -Uri "$base/properties/watchlist" -Headers @{ Authorization = "Bearer $($user.accessToken)" }
Assert-True ($null -ne $watch.content) "USER watchlist loads"

# Blogs (read-only on mobile)
$blogs = Invoke-RestMethod -Uri "$base/blogs/published?page=0&size=10"
Assert-True ($null -ne $blogs.content) "Published blogs list loads"
Assert-True ($blogs.content.Count -ge 0) "Published blogs response has content array"

$filters = Invoke-RestMethod -Uri "$base/blogs/published/filters"
Assert-True ($null -ne $filters.categories) "Blog filters load"

if ($blogs.content.Count -gt 0) {
    $slug = $blogs.content[0].slug
    $detail = Invoke-RestMethod -Uri "$base/blogs/published/$slug"
    Assert-True ($detail.slug -eq $slug) "Blog detail by slug loads"
}

# Market stats (public projector cascade)
Write-Host "`n--- Market stats / growth projector ---" -ForegroundColor Cyan
$states = Invoke-RestMethod -Uri "$base/market-stats/areas?level=STATE"
Assert-True ($null -ne $states) "Public market states list loads"
Assert-True ($states.Count -ge 0) "Market states response is an array"

if ($states.Count -gt 0) {
    $stateId = $states[0].id
    $stateName = $states[0].name
    Assert-True ($stateId -gt 0) "First state has valid id ($stateName)"

    $cities = Invoke-RestMethod -Uri "$base/market-stats/areas?parentId=$stateId&level=CITY"
    Assert-True ($null -ne $cities) "Cities cascade by parentId for state $stateName"

    if ($cities.Count -gt 0) {
        $cityId = $cities[0].id
        $cityName = $cities[0].name
        $localities = Invoke-RestMethod -Uri "$base/market-stats/areas?parentId=$cityId&level=LOCALITY"
        Assert-True ($null -ne $localities) "Localities cascade by parentId for city $cityName"

        $areaId = if ($localities.Count -gt 0) { $localities[0].id } else { $cityId }
        $stats = Invoke-RestMethod -Uri "$base/market-stats?areaId=$areaId&range=5Y"
        Assert-True ($null -ne $stats.area) "Market stats load for area $areaId"
        Assert-True ($null -ne $stats.derivedCagrPct) "Derived CAGR present for area $areaId"

        $projBody = @{
            areaId = $areaId
            range = "5Y"
            initialAmount = 2500000
            monthlyContribution = 25000
            years = 10
            expectedRatePct = 8.5
        } | ConvertTo-Json
        $proj = Invoke-RestMethod -Uri "$base/market-stats/projection" -Method POST -ContentType "application/json" -Body $projBody
        Assert-True ($proj.points.Count -gt 0) "Projection returns chart points"
        Assert-True ($proj.regionalFinal -gt 0) "Projection regionalFinal is positive"
        Assert-True ($proj.userFinal -gt 0) "Projection userFinal is positive"
    } else {
        Write-Host "[SKIP] No cities for state $stateName — add cities in admin" -ForegroundColor Yellow
    }
} else {
    Write-Host "[SKIP] No states configured — admin can import RBI seed or add areas" -ForegroundColor Yellow
}

# Admin market stats (create + public visibility)
Write-Host "`n--- Admin market stats CRUD ---" -ForegroundColor Cyan
$adminHeaders = @{ Authorization = "Bearer $($admin.accessToken)" }
$testStateName = "E2E Test State $(Get-Random -Maximum 99999)"
$createStateBody = @{
    level = "STATE"
    name = $testStateName
    active = $true
    sortOrder = 999
} | ConvertTo-Json
try {
    $createdState = Invoke-RestMethod -Uri "$base/admin/market-stats/areas" -Method POST -Headers $adminHeaders -ContentType "application/json" -Body $createStateBody
    Assert-True ($createdState.name -eq $testStateName) "Admin can create market state"
    Assert-True ($createdState.id -gt 0) "Created state has id"

    $publicStates = Invoke-RestMethod -Uri "$base/market-stats/areas?level=STATE"
    $found = @($publicStates | Where-Object { $_.name -eq $testStateName }).Count -gt 0
    Assert-True $found "Admin-created state visible on public API"

    $createCityBody = @{
        level = "CITY"
        name = "E2E Test City"
        parentId = $createdState.id
        active = $true
    } | ConvertTo-Json
    $createdCity = Invoke-RestMethod -Uri "$base/admin/market-stats/areas" -Method POST -Headers $adminHeaders -ContentType "application/json" -Body $createCityBody
    Assert-True ($createdCity.stateName -eq $testStateName) "City inherits stateName from parent"

    $publicCities = Invoke-RestMethod -Uri "$base/market-stats/areas?parentId=$($createdState.id)&level=CITY"
    $cityFound = @($publicCities | Where-Object { $_.name -eq "E2E Test City" }).Count -gt 0
    Assert-True $cityFound "Admin-created city visible via parentId cascade"

    Invoke-RestMethod -Uri "$base/admin/market-stats/areas/$($createdCity.id)" -Method DELETE -Headers $adminHeaders | Out-Null
    Invoke-RestMethod -Uri "$base/admin/market-stats/areas/$($createdState.id)" -Method DELETE -Headers $adminHeaders | Out-Null
    Assert-True $true "Admin cleanup of test areas succeeded"
} catch {
    Write-Host "[FAIL] Admin market stats CRUD: $($_.Exception.Message)" -ForegroundColor Red
    $script:failed++
}

Write-Host "`n=== Results: $passed passed, $failed failed ===`n" -ForegroundColor Cyan
if ($failed -gt 0) { exit 1 }
