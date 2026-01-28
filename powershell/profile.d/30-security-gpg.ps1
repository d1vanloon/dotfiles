# Encryption/Decryption shortcuts for GPG
# These need parameter cleanups and documentation

function Write-EncryptedVersion {
    Param ([string[]]$FileNames, [switch]$AsJob)

    foreach ($FileName in $FileNames) {
        $new_filename = "$FileName.gpg"

        if ($AsJob) {
            gpg -o "$new_filename" -ser david@vanloon.family "$FileName" &
        }
        else {
            gpg -o "$new_filename" -ser david@vanloon.family "$FileName"
        }
    }
}

function Write-Signature {
    Param ([string]$filename)

    gpg -o "$filename.sig" -s "$filename"
}

function Write-DecryptedVersion {
    Param ([string[]]$FileNames, [switch]$AsJob)

    foreach ($FileName in $FileNames) {
        $new_filename = $FileName -replace '.gpg'

        if ($AsJob) {
            gpg -o "$new_filename" -d "$FileName" &
        }
        else {
            gpg -o "$new_filename" -d "$FileName"
        }
    }
}
