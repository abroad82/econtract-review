// Ordered, sectioned page manifest for the e-contract.com.au LANDING review board.
// {n:name, f:saved file, live:live URL, g:section, s:sub-heading}
// All pages are LOGGED-OUT (the pre-launch landing) — no login needed to capture.
// When the real site moves over from Beta, expand this list (the contco manifest's
// full page set can be reused — just keep base L pointed at e-contract.com.au).
var L = "https://e-contract.com.au/";
window.WB_PAGES = [

/* ============================================================
   1 · ENTRY & REGISTER
   ============================================================ */
{g:"1 · Entry & Register", s:"Home", n:"Home",                    f:"EC01_home.html",                 live:L},
{g:"1 · Entry & Register", s:"Register your interest", n:"Register — Employee",  f:"EC02_register-employee.html",   live:L+"register-interest-employee"},
{g:"1 · Entry & Register", s:"Register your interest", n:"Register — Contractor",f:"EC03_register-contractor.html", live:L+"register-interest"},
{g:"1 · Entry & Register", s:"Register your interest", n:"Register — Thank You", f:"EC04_register-thanks.html",      live:L+"register-interest-thanks"},
{g:"1 · Entry & Register", s:"Legal", n:"Privacy Policy",         f:"EC05_privacy.html",              live:L+"privacy-policy"},

/* ============================================================
   2 · BROWSE  (sample data — what a video visitor sees)
   ============================================================ */
{g:"2 · Browse (sample data)", s:"Hubs", n:"Find a Contractor — Hub", f:"EC06_find-contractor-hub.html", live:L+"search/find_me_worker"},
{g:"2 · Browse (sample data)", s:"Hubs", n:"Find an Employee — Hub",  f:"EC07_find-employee-hub.html",   live:L+"search/find_me_worker?find=employee"},
{g:"2 · Browse (sample data)", s:"Results", n:"Contractors — Directory", f:"EC08_contractors-directory.html", live:L+"search/find_me_worker?search=worker"},
{g:"2 · Browse (sample data)", s:"Results", n:"Jobs Board",          f:"EC09_jobs-board.html",          live:L+"search/find_me_work?search=work"},
{g:"2 · Browse (sample data)", s:"Job detail", n:"Job Detail — Direct Hire", f:"EC10_job-detail.html",   live:L+"search/work/780"},
{g:"2 · Browse (sample data)", s:"Job detail", n:"Job Detail — Quote form",  f:"EC11_job-detail-quote.html", live:L+"search/work/780?quote=1"},

/* ============================================================
   3 · POST A JOB  (guest can fill, blocked at finalise -> register)
   ============================================================ */
{g:"3 · Post a job (guest)", s:"Create", n:"Create a Job",        f:"EC12_create-job.html",          live:L+"myaccount/create_job"},
{g:"3 · Post a job (guest)", s:"Create", n:"Need Someone Now",    f:"EC13_quick-job.html",           live:L+"myaccount/create_quick_job"}

];
