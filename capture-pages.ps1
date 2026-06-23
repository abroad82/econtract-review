<#
  capture-pages.ps1  -  Refresh contco Review Board captures straight from the LIVE site.

  Pulls raw server HTML for each page (exactly what the dev copies & pastes), injects
  <base href> so live CSS/JS/images load inside the iframe, and adds the wb-uifix jQuery
  shim for parity with the existing captures. Byte-faithful otherwise.

  AUTH (two ways):
    -CiSession '<ci_session cookie value>'   # one-off; uses an existing logged-in session
    -Email x -Pass y                         # preferred for automation; logs in fresh each run

  ROLES:
    loggedout    ~27 public pages (no auth)
    contractor   Principal + Sub-contractor + contractor-side Shared + public profiles
    emp          Employee section + employee-side Shared

  Output -> pages-live\_recapture\<role>\  (staging - nothing overwritten/deployed).
  Credentials/cookies are used in-session only and never written to disk.
#>
param(
  [ValidateSet('loggedout','contractor','emp')] [string]$Role = 'loggedout',
  [string]$CiSession,
  [string]$Email,
  [string]$Pass,
  [switch]$Promote,     # write straight into pages-live (overwrite), not the staging folder
  [string]$Root         # override pages-live location; defaults to <scriptdir>/pages-live
)

$ErrorActionPreference = 'Stop'
$LIVE  = 'https://contco.com.au/'
$UA    = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
$ROOT  = if ($Root) { $Root } else { Join-Path $PSScriptRoot 'pages-live' }
$STAGE = Join-Path $ROOT (Join-Path '_recapture' $Role)
$OUT   = if ($Promote) { $ROOT } else { $STAGE }
New-Item -ItemType Directory -Force -Path $OUT | Out-Null

$shim = '<script>/*wb-uifix*/(function(){if(window.jQuery){var n=function(){return this;};["datepicker","sortable","draggable","droppable","resizable","tabs","accordion","dialog","autocomplete","slider","tooltip","menu","selectmenu","spinner"].forEach(function(m){if(!jQuery.fn[m])jQuery.fn[m]=n;});}})();</script>'

function Transform([string]$html) {
  if ($html -notmatch '(?i)<base\b') {
    $html = [regex]::Replace($html, '(?i)(<head[^>]*>)', "`$1`n<base href=`"$LIVE`">", 1)
  }
  if ($html -notmatch 'wb-uifix') {
    $m = [regex]::Match($html, '(?i)<script[^>]*jquery[^>]*></script>')
    if ($m.Success) { $html = $html.Insert($m.Index + $m.Length, "`n$shim") }
  }
  # Strip the per-request cache-buster timestamp (e.g. ...?id=1781096012, PHP time()) so an UNCHANGED
  # page captures byte-identical each run -> the Daily Log shows only REAL dev changes, not noise.
  $html = [regex]::Replace($html, '([?&]id=)\d{9,}', '${1}0')
  return $html
}

# --- page maps: f=file, u=live path, v=$true means "same live URL as a base file -> skip (UI-state variant)"
$loggedout = @(
  @{f='LO01_home.html';u=''}, @{f='LO03_home-contractor.html';u='?home=contractor'}, @{f='LO02_home-employee.html';u='?home=employee'},
  @{f='LO04_login.html';u='user/login'}, @{f='LO05_signup-contractor.html';u='user/signup'}, @{f='LO06_signup-employee.html';u='signup_employee'},
  @{f='LO07_forgot-password.html';u='user/forgot_password'}, @{f='LO08_thankyou.html';u='user/thankyou'}, @{f='LO09_contact.html';u='contact'},
  @{f='LO10_faq-site-info.html';u='tips-hints'}, @{f='LO11_about-us.html';u='about-us'}, @{f='LO12_terms-conditions.html';u='terms-condition'},
  @{f='LO13_feedback.html';u='feedback'},
  @{f='PC01_find-a-contractor-form.html';u='search/find_me_worker'}, @{f='PC02_find-a-contractor-results.html';u='search/find_me_worker?search=worker'},
  @{f='PC03_find-an-employee-form.html';u='search/find_me_worker?find=employee'}, @{f='PC04_find-an-employee-results.html';u='search/find_me_worker?find=employee&search=worker'},
  @{f='SC01_find-a-contract-form.html';u='search/find_me_work'}, @{f='SC02_find-a-contract-results.html';u='search/find_me_work?search=work'},
  @{f='SC03_job-detail-direct-hire.html';u='search/work/781'}, @{f='SC04_job-detail-quote.html';u='search/work/786'},
  @{f='EMP01_find-short-term-form.html';u='search/find_me_work?job_type=short'}, @{f='EMP02_find-short-term-results.html';u='search/find_me_work?job_type=short&search=work'},
  @{f='EMP05_job-detail-short-term.html';u='search/work/796'},
  @{f='EMP03_find-full-time-form.html';u='search/find_me_work?job_type=full'}, @{f='EMP04_find-full-time-results.html';u='search/find_me_work?job_type=full&search=work'},
  @{f='EMP06_job-detail-full-time.html';u='search/work/803'}
)

$contractor = @(
  # -- 2 Principal Contractor --
  @{f='SH03_dashboard-contractor.html';u='user/dashboard'}, @{f='SH00_myaccount-contractor.html';u='myaccount'},
  @{f='HOMEc_home-loggedin-contractor.html';u=''},
  @{f='PC02L_find-contractor-results.html';u='search/find_me_worker?search=worker'}, @{f='PC04L_find-employee-results.html';u='search/find_me_worker?find=employee&search=worker'},
  @{f='PC01L_find-contractor-form-loggedin.html';u='search/find_me_worker'}, @{f='PC03L_find-employee-form-loggedin.html';u='search/find_me_worker?find=employee'},
  @{f='SC01L_find-contract-form-loggedin.html';u='search/find_me_work'}, @{f='SC02L_find-contract-results-loggedin.html';u='search/find_me_work?search=work'},
  @{f='PC05_create-job.html';u='myaccount/create_job'}, @{f='PC05q_create-job-quote.html';u='myaccount/create_job';v=$true},
  @{f='PC06_create-job-employee.html';u='myaccount/create_job?find=employee'}, @{f='PC06f_create-job-employee-full.html';u='myaccount/create_job?find=employee';v=$true},
  @{f='PC07_need-someone-now.html';u='myaccount/create_quick_job'}, @{f='PC07e_need-someone-now-employee.html';u='myaccount/create_quick_job?find=employee'}, @{f='PC07f_need-someone-now-employee-full.html';u='myaccount/create_quick_job?find=employee';v=$true},
  @{f='PCjd_job-detail-direct-hire.html';u='search/work/781'}, @{f='PCjdq_job-detail-quote.html';u='search/work/786'}, @{f='PCown_job-detail-owner-809.html';u='search/work/809'},
  @{f='PC09_edit-job.html';u='myaccount/edit_job/809?t=c'},
  @{f='PC08_my-created-jobs.html';u='myaccount/my_job'}, @{f='PC-requests.html';u='myaccount/requests'}, @{f='PC-employee-agreement.html';u='myaccount/employee_agreement'},
  @{f='PC14_previous-jobs.html';u='myaccount/previous_works'}, @{f='PC12_quicklist-workers.html';u='myaccount/quick_list_worker'},
  @{f='PC08s_my-jobs-emp-short.html';u='myaccount/my_job?job_type=short'}, @{f='PC-requests-short.html';u='myaccount/requests?job_type=short'}, @{f='PC-employee-agreement-short.html';u='myaccount/employee_agreement?job_type=short'},
  @{f='PC14s_previous-short.html';u='myaccount/previous_works?job_type=short'}, @{f='PC12s_quicklist-workers-short.html';u='myaccount/quick_list_worker?job_type=short'},
  @{f='PC08f_my-jobs-emp-full.html';u='myaccount/my_job?job_type=full'}, @{f='PC-requests-full.html';u='myaccount/requests?job_type=full'}, @{f='PC-employee-agreement-full.html';u='myaccount/employee_agreement?job_type=full'},
  @{f='PC14f_previous-full.html';u='myaccount/previous_works?job_type=full'}, @{f='PC12f_quicklist-workers-full.html';u='myaccount/quick_list_worker?job_type=full'},
  # -- 3 Sub-contractor --
  @{f='PCsc-sent-contractor.html';u='myaccount/sent'}, @{f='PC10_received-requests.html';u='myaccount/received'},
  @{f='PC11_employer-agreement.html';u='myaccount/employer_agreement'}, @{f='PCsc-quicklist-contractor.html';u='myaccount/quick_list'},
  # -- 6 Shared (contractor account menu) --
  @{f='SH04c_edit-profile-contractor.html';u='user/edit_profile'}, @{f='SH05_gallery-contractor.html';u='user/gallery'}, @{f='SH06_contacts-contractor.html';u='myaccount/contacts'},
  @{f='SH07_inbox-contractor.html';u='myaccount/inbox'}, @{f='SH08_outbox-contractor.html';u='myaccount/outbox'}, @{f='SH09_calendar-contractor.html';u='user/calendar'}, @{f='SHchangepass-contractor.html';u='user/changepass'},
  # -- 6 Shared (public profiles, anyone) --
  @{f='SH01_profile-contractor-470.html';u='user/view/470'}, @{f='SH01b_profile-contractor-471.html';u='user/view/471'}, @{f='SH02_profile-employee-487.html';u='user/view/487'}
)

$emp = @(
  @{f='SH03_dashboard-employee.html';u='user/dashboard'}, @{f='SH00_myaccount-employee.html';u='myaccount'},
  @{f='HOMEe_home-loggedin-employee.html';u=''}, @{f='EMP01L_find-short-form-loggedin.html';u='search/find_me_work?job_type=short'}, @{f='EMP03L_find-full-form-loggedin.html';u='search/find_me_work?job_type=full'}, @{f='EMP06L_job-detail-full-loggedin.html';u='search/work/803'},
  @{f='EMP02L_results-short-loggedin.html';u='search/find_me_work?job_type=short&search=work'}, @{f='EMP05L_job-detail-short-loggedin.html';u='search/work/796'}, @{f='EMP05a_job-detail-short-agreement.html';u='search/work/796?agreement=1'},
  @{f='EMP09_sent-short.html';u='myaccount/sent?job_type=short'}, @{f='EMP11_received-short.html';u='myaccount/received?job_type=short'}, @{f='EMP13_agreements-short.html';u='myaccount/employer_agreement?job_type=short'}, @{f='EMP15_quicklist-short.html';u='myaccount/quick_list?job_type=short'},
  @{f='EMP04L_results-full-loggedin.html';u='search/find_me_work?job_type=full&search=work'}, @{f='EMP10_sent-full.html';u='myaccount/sent?job_type=full'}, @{f='EMP12_received-full.html';u='myaccount/received?job_type=full'}, @{f='EMP14_agreements-full.html';u='myaccount/employer_agreement?job_type=full'}, @{f='EMP16_quicklist-full.html';u='myaccount/quick_list?job_type=full'},
  @{f='SH04_edit-profile-employee.html';u='user/edit_profile'}, @{f='SH05_gallery-employee.html';u='user/gallery'}, @{f='SH06_contacts-employee.html';u='myaccount/contacts'},
  @{f='SH07_inbox-employee.html';u='myaccount/inbox'}, @{f='SH08_outbox-employee.html';u='myaccount/outbox'}, @{f='SH09_calendar-employee.html';u='user/calendar'}
)

# --- build session ----------------------------------------------------------
$session = $null
if ($Role -ne 'loggedout') {
  $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
  $session.UserAgent = $UA
  if ($CiSession) {
    $session.Cookies.Add((New-Object System.Net.Cookie('ci_session',$CiSession,'/','contco.com.au')))
  } elseif ($Email -and $Pass) {
    $lp = Invoke-WebRequest -Uri ($LIVE+'user/login') -WebSession $session -UseBasicParsing   # GET sets the ci_csrf cookie
    $csrf = ''   # CSRF protection was enabled on the site ~2026-06-17; performlogin now 500s without the token
    if ($lp.Content -match '(?is)<input[^>]*name="ci_csrf_token"[^>]*value="([0-9a-f]+)"') { $csrf = $matches[1] }
    elseif ($lp.Content -match '(?is)<input[^>]*value="([0-9a-f]+)"[^>]*name="ci_csrf_token"') { $csrf = $matches[1] }
    $loginBody = @{username=$Email;password=$Pass;remember_me='1'}
    if ($csrf -ne '') { $loginBody['ci_csrf_token'] = $csrf }
    Invoke-WebRequest -Uri ($LIVE+'user/performlogin') -Method Post -Body $loginBody -WebSession $session -UseBasicParsing | Out-Null
  } else { throw "Role '$Role' needs -CiSession OR (-Email and -Pass)." }
  # verify
  $d = Invoke-WebRequest -Uri ($LIVE+'user/dashboard') -WebSession $session -UseBasicParsing
  if ($d.Content -match '(?i)Please wait while your request is being verified|One moment, please|Just a moment|Checking your browser|cf-browser-verification|challenge-platform') { throw "BOT CHALLENGE on login (datacenter IP challenged) - aborting." }
  if ($d.Content -match '(?i)performlogin|name=["'']password["'']') { throw "NOT logged in - session/credentials rejected (IP or UA mismatch?)." }
  $who = [regex]::Match($d.Content,'(?i)Welcome\s+([^<]{1,40})').Groups[1].Value.Trim()
  Write-Host ("Logged in OK ({0})" -f $who) -ForegroundColor Green
}

$map = switch ($Role) { 'loggedout'{$loggedout} 'contractor'{$contractor} 'emp'{$emp} }

"{0,-44} {1,9} {2,9}  {3}" -f 'FILE','NEW(kb)','OLD(kb)','STATUS' | Write-Host
$cap=0; $skip=0; $fail=0
foreach ($p in $map) {
  if ($p.v) { "{0,-44} {1,9} {2,9}  {3}" -f $p.f,'-','-','skip (variant of base URL)' | Write-Host; $skip++; continue }
  $url = $LIVE + $p.u
  try {
    if ($session) { $r = Invoke-WebRequest -Uri $url -WebSession $session -UseBasicParsing } else { $r = Invoke-WebRequest -Uri $url -UseBasicParsing }
    # decode the raw bytes as UTF-8 so captures are byte-identical across machines (PS 5.1, pwsh 7) - fixes dash mojibake
    $content = if ($r.RawContentStream) { [System.Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray()) } else { [string]$r.Content }
    if ($content -match '(?i)Please wait while your request is being verified|One moment, please|Just a moment|Checking your browser|cf-browser-verification|challenge-platform') { throw "BOT CHALLENGE: $url" }
    if ($session -and ($content -match '(?i)name=["'']password["''].*performlogin|performlogin')) { throw "got a login page (session expired mid-run)" }
    $html = Transform $content
    $newKb = [math]::Round($html.Length/1kb,1)
    $oldPath = Join-Path $ROOT $p.f
    if (Test-Path $oldPath) {
      $oldKb=[math]::Round((Get-Item $oldPath).Length/1kb,1); $delta=[math]::Round($newKb-$oldKb,1)
      $sign = if ($delta -ge 0) {'+'} else {''}
      $status = if ([math]::Abs($delta) -ge 2) { "CHANGED ($sign$delta kb)" } else { 'same' }
    } else { $oldKb='-'; $status='NEW' }
    [System.IO.File]::WriteAllText((Join-Path $OUT $p.f), $html, (New-Object System.Text.UTF8Encoding($false)))
    "{0,-44} {1,9} {2,9}  {3}" -f $p.f,$newKb,$oldKb,$status | Write-Host
    $cap++
  } catch { if ($_.Exception.Message -match 'BOT CHALLENGE') { throw }   # hard-abort the whole run so no garbage is committed/deployed
            "{0,-44} {1,9} {2,9}  FAILED: {3}" -f $p.f,'-','-',$_.Exception.Message | Write-Host; $fail++ }
}
Write-Host ("`n{0} captured / {1} skipped / {2} failed   ->  {3}" -f $cap,$skip,$fail,$OUT) -ForegroundColor Cyan
