IF (Get-CimInstance -ClassName Win32_UserProfile -Filter "Loaded=False and LocalPath Like '%username%'" ) {

    Write-Host "User Profile found and not loaded, Proceed deletion"
    Exit 1
    }
    
    else {
    
    Write-Host "User Profile loaded or not Found, Cancel Deletion"
    Exit 0
    
    }