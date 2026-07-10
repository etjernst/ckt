$ErrorActionPreference = 'SilentlyContinue'

$outDir = "C:/git/ckt/.claude/worktrees/lca-inversion/explorations/python-grc/stata/step0_5_summclust_preflight/output"
$stamp  = Get-Date -Format 'yyyyMMdd_HHmmss'
$out    = "$outDir/monitor_v2_$stamp.csv"

# Header. Per-core values are pipe-separated strings to keep column count manageable.
$header = "timestamp,cpu_pct,cpu_perf_pct,mem_used_gb,mem_commit_gb,mem_commit_limit_gb,pagefile_pct,stata_count,stata_pids,stata_ws_gb_total,stata_cpu_sec_total,stata_threads_total,perf_per_core,util_per_core"
$header | Out-File -FilePath $out -Encoding utf8

$cores = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
"# logical_cores=$cores" | Out-File -FilePath $out -Append -Encoding utf8
"# header_repeated_below" | Out-File -FilePath $out -Append -Encoding utf8
$header | Out-File -FilePath $out -Append -Encoding utf8

function Sort-CoreInstance {
    param($s)
    # Sorts core instance names like "0", "1", ..., "21" or "0,0", "0,1", ..., "0,21" numerically.
    $s | Sort-Object @{Expression = {
        $parts = $_.InstanceName -split ','
        if ($parts.Count -eq 2) {
            [int]$parts[0] * 1000 + [int]$parts[1]
        } else {
            [int]$_.InstanceName
        }
    }}
}

while ($true) {
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    try { $cpu = (Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop).CounterSamples[0].CookedValue } catch { $cpu = '' }
    try { $perf = (Get-Counter '\Processor Information(_Total)\% Processor Performance' -ErrorAction Stop).CounterSamples[0].CookedValue } catch { $perf = '' }

    # Per-core performance and utilization
    $perfPerCore = ''
    $utilPerCore = ''
    try {
        $perfSamples = (Get-Counter '\Processor Information(*)\% Processor Performance' -ErrorAction Stop).CounterSamples
        $perfCores = Sort-CoreInstance ($perfSamples | Where-Object { $_.InstanceName -notmatch '[Tt]otal' })
        $perfPerCore = (($perfCores | ForEach-Object { [math]::Round($_.CookedValue, 1) }) -join '|')

        $utilSamples = (Get-Counter '\Processor Information(*)\% Processor Time' -ErrorAction Stop).CounterSamples
        $utilCores = Sort-CoreInstance ($utilSamples | Where-Object { $_.InstanceName -notmatch '[Tt]otal' })
        $utilPerCore = (($utilCores | ForEach-Object { [math]::Round($_.CookedValue, 1) }) -join '|')
    } catch {
        $perfPerCore = ''
        $utilPerCore = ''
    }

    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($os) {
        $memUsed       = ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB
        $memCommit     = ($os.TotalVirtualMemorySize - $os.FreeVirtualMemory) / 1MB
        $memCommitLim  = $os.TotalVirtualMemorySize / 1MB
    } else {
        $memUsed = ''; $memCommit = ''; $memCommitLim = ''
    }

    try { $pf = (Get-Counter '\Paging File(_Total)\% Usage' -ErrorAction Stop).CounterSamples[0].CookedValue } catch { $pf = '' }

    # Capture ALL StataMP-64 processes (the v1 monitor missed this when multiple were alive)
    $stProcs = @(Get-Process -Name StataMP-64 -ErrorAction SilentlyContinue)
    if ($stProcs.Count -gt 0) {
        $stCount   = $stProcs.Count
        $stPids    = ($stProcs.Id -join '|')
        $stWS      = ($stProcs | Measure-Object -Property WorkingSet64 -Sum).Sum / 1GB
        $stCPU     = ($stProcs | Measure-Object -Property CPU -Sum).Sum
        $stThreads = ($stProcs | ForEach-Object { $_.Threads.Count } | Measure-Object -Sum).Sum
    } else {
        $stCount = 0; $stPids = ''; $stWS = ''; $stCPU = ''; $stThreads = ''
    }

    $row = "{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12},{13}" -f `
        $ts,
        ($(if ($cpu -ne '') { [math]::Round($cpu,1) } else { '' })),
        ($(if ($perf -ne '') { [math]::Round($perf,1) } else { '' })),
        ($(if ($memUsed -ne '') { [math]::Round($memUsed,2) } else { '' })),
        ($(if ($memCommit -ne '') { [math]::Round($memCommit,2) } else { '' })),
        ($(if ($memCommitLim -ne '') { [math]::Round($memCommitLim,2) } else { '' })),
        ($(if ($pf -ne '') { [math]::Round($pf,2) } else { '' })),
        $stCount,
        $stPids,
        ($(if ($stWS -ne '') { [math]::Round($stWS,3) } else { '' })),
        ($(if ($stCPU -ne '') { [math]::Round($stCPU,1) } else { '' })),
        $stThreads,
        $perfPerCore,
        $utilPerCore

    $row | Out-File -FilePath $out -Append -Encoding utf8

    Start-Sleep -Seconds 5
}
