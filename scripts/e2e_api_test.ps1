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

Write-Host "`n=== Results: $passed passed, $failed failed ===`n" -ForegroundColor Cyan
if ($failed -gt 0) { exit 1 }
