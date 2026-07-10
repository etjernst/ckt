$ErrorActionPreference = 'SilentlyContinue'

$outDir = "C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output"
$stamp  = Get-Date -Format 'yyyyMMdd_HHmmss'
$out    = "$outDir/monitor_$stamp.csv"

$header = "timestamp,cpu_pct,cpu_perf_pct,mem_used_gb,mem_commit_gb,mem_commit_limit_gb,pagefile_pct,stata_pid,stata_ws_gb,stata_cpu_sec,stata_threads"
$header | Out-File -FilePath $out -Encoding utf8

$cores = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
"# logical_cores=$cores" | Out-File -FilePath $out -Append -Encoding utf8
"# header_repeated_below" | Out-File -FilePath $out -Append -Encoding utf8
$header | Out-File -FilePath $out -Append -Encoding utf8

while ($true) {
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    try { $cpu = (Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop).CounterSamples[0].CookedValue } catch { $cpu = '' }
    try { $perf = (Get-Counter '\Processor Information(_Total)\% Processor Performance' -ErrorAction Stop).CounterSamples[0].CookedValue } catch { $perf = '' }

    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($os) {
        $memUsed       = ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB
        $memCommit     = ($os.TotalVirtualMemorySize - $os.FreeVirtualMemory) / 1MB
        $memCommitLim  = $os.TotalVirtualMemorySize / 1MB
    } else {
        $memUsed = ''; $memCommit = ''; $memCommitLim = ''
    }

    try { $pf = (Get-Counter '\Paging File(_Total)\% Usage' -ErrorAction Stop).CounterSamples[0].CookedValue } catch { $pf = '' }

    $st = Get-Process -Name StataMP-64 -ErrorAction SilentlyContinue
    if ($st) {
        $stPid     = $st.Id
        $stWS      = $st.WorkingSet64 / 1GB
        $stCPU     = $st.CPU
        $stThreads = $st.Threads.Count
    } else {
        $stPid = ''; $stWS = ''; $stCPU = ''; $stThreads = ''
    }

    $row = "{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10}" -f `
        $ts,
        ($(if ($cpu -ne '') { [math]::Round($cpu,1) } else { '' })),
        ($(if ($perf -ne '') { [math]::Round($perf,1) } else { '' })),
        ($(if ($memUsed -ne '') { [math]::Round($memUsed,2) } else { '' })),
        ($(if ($memCommit -ne '') { [math]::Round($memCommit,2) } else { '' })),
        ($(if ($memCommitLim -ne '') { [math]::Round($memCommitLim,2) } else { '' })),
        ($(if ($pf -ne '') { [math]::Round($pf,2) } else { '' })),
        $stPid,
        ($(if ($stWS -ne '') { [math]::Round($stWS,3) } else { '' })),
        ($(if ($stCPU -ne '') { [math]::Round($stCPU,1) } else { '' })),
        $stThreads

    $row | Out-File -FilePath $out -Append -Encoding utf8

    Start-Sleep -Seconds 5
}
