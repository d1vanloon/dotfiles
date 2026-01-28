function Invoke-VideoFileTranscription() {
    [CmdletBinding()]
    param (
        # Specifies a path to the input video file.
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Path to the input video file.")]
        [Alias("PSPath")]
        [ValidateNotNullOrEmpty()]
        [string]
        $InputFilePath,
        [Parameter(Position = 1)]
        [ValidateSet("cpu", "cuda")]
        [string]
        $Device = "cuda"
    )

    # Create a temporary directory with a random name
    $TempDirInfo = New-Item -ItemType Directory -Path (Join-Path $env:TEMP (New-Guid).ToString())
    $TempDir = $TempDirInfo.FullName
    Write-Host "Created temporary directory at $TempDir"

    try {
        # Get the directory of the input file
        $InputFileDir = Split-Path -Path $InputFilePath -Parent
        # Get the base name of the input file without extension
        $InputFileName = [System.IO.Path]::GetFileNameWithoutExtension($InputFilePath)

        Write-Host "Extracting audio from '$InputFilePath'"
        # Extract audio from the video file using ffmpeg
        $AudioFilePath = Join-Path $TempDir "$InputFileName.m4a"
        $ffmpegResult = & ffmpeg -y -i $InputFilePath -vn -acodec copy $AudioFilePath 2>&1
        if ($LASTEXITCODE -ne 0 -or !(Test-Path $AudioFilePath)) {
            Write-Error "ffmpeg failed to extract audio: $ffmpegResult"
            return
        }
        Write-Host "Audio extracted to '$AudioFilePath'"

        # Use Whisper to transcribe the audio file
        $whisperExe = $null
        Write-Host "Locating Whisper executable"
        $whisperExeCandidates = @(
            $env:WHISPER_CLI_PATH,
            (Join-Path $env:LOCALAPPDATA "Packages\PythonSoftwareFoundation.Python.3.13_qbz5n2kfra8p0\LocalCache\local-packages\Python313\Scripts\whisper.exe"),
            (Join-Path $env:LOCALAPPDATA "anaconda3\envs\whisper\Scripts\whisper.exe")
        ) | Where-Object { $_ -and $_.Trim() }

        foreach ($candidate in $whisperExeCandidates) {
            $expandedCandidate = [System.Environment]::ExpandEnvironmentVariables($candidate)
            if (Test-Path $expandedCandidate) {
                $whisperExe = $expandedCandidate
                Write-Host "Using Whisper executable at '$whisperExe'"
                break
            }
        }

        if (-not $whisperExe) {
            $commandInfo = Get-Command whisper -ErrorAction SilentlyContinue
            if ($commandInfo -and $commandInfo.Source -and (Test-Path $commandInfo.Source)) {
                $whisperExe = $commandInfo.Source
                Write-Host "Using Whisper executable discovered via PATH at '$whisperExe'"
            }
        }

        if (-not $whisperExe) {
            $testedCandidates = ($whisperExeCandidates -join ', ')
            Write-Error "Whisper executable not found. Candidates tested: $testedCandidates"
            return
        }
        Write-Host "Transcribing audio with Whisper"
        $whisperResult = & $whisperExe "$AudioFilePath" --model turbo --language English --output_format txt --output_dir "$InputFileDir" --device $Device 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Whisper transcription failed: $whisperResult"
            return
        }
        $transcriptPath = Join-Path $InputFileDir "$InputFileName.txt"
        Write-Host "Transcription complete. Check '$transcriptPath' for results."
    }
    catch {
        Write-Error "Transcription process failed: $_"
    }
    finally {
        # Clean up the temporary directory
        if (Test-Path $TempDir) {
            Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
