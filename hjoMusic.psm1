function Find-DzrUser {
    [cmdletbinding(DefaultParameterSetName='NoProxy')]
    Param(
        [Parameter(ParameterSetName='NoProxy', Position=0, Mandatory=$true)]
        [Parameter(ParameterSetName='WithProxy', Position=0, Mandatory=$true)]    
        [Alias('Filter')]
        [string]$Name,

        [Parameter(ParameterSetName='WithProxy')]
        [uri]$Proxy,
        
        [Parameter(ParameterSetName='WithProxy')]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        [PSCredential]$ProxyCredential = [System.Management.Automation.PSCredential]::Empty
    ) # Param
        
    BEGIN {
        Write-Verbose ""
        Write-Verbose "--- Executing Metadata ---"
        Write-Verbose "User = $($env:userdomain)\$($env:USERNAME)"
        Write-Verbose "Is Admin = $IsAdmin"
        Write-Verbose "Computername = $env:COMPUTERNAME"
        Write-Verbose "Host = $($host.Name)"
        Write-Verbose "PSVersion = $($PSVersionTable.PSVersion)"
        Write-Verbose "Runtime = $(Get-Date)"
        Write-Verbose "--- End Metadata ---"
        Write-Verbose ""
    }
        
    PROCESS {
        # Get first page of data
        $URL = "https://api.deezer.com/search/user?q='" + $Name + "'"

        If ($PSCmdlet.ParameterSetName -eq "NoProxy") {
            $Users = Invoke-RestMethod -Uri $URL
        } elseif (($PSCmdlet.ParameterSetName -eq "WithProxy") -and ($PSBoundParameters.ContainsKey('ProxyCredential') -eq $false)) {
            $Users = Invoke-RestMethod -Uri $URL -Proxy $Proxy -ProxyUseDefaultCredentials
        } else {
           $Users = Invoke-RestMethod -Uri $URL -Proxy $Proxy -ProxyCredential $ProxyCredential
        }
            
        do {
            # Output the current page of data
            $Users.data | Select-Object -Property @{name='Name';expression={$_.name}},
                                                  @{name='UserID';expression={$_.id}},
                                                  @{name='Type';expression={$_.type}},
                                                  @{name='UriPicture1';expression={$_.picture_small}},
                                                  @{name='UriPicture2';expression={$_.picture}},
                                                  @{name='UriPicture3';expression={$_.picture_medium}},
                                                  @{name='UriPicture4';expression={$_.picture_big}},
                                                  @{name='UriPicture5';expression={$_.picture_xl}},
                                                  @{name='UriTracklist';expression={$_.tracklist}}
            # Get the following pages of data
            if ($Users.next) {
                $MorePages = $true
                If ($PSCmdlet.ParameterSetName -eq "NoProxy") {
                    $Users = Invoke-RestMethod -uri $Users.next
                } elseif (($PSCmdlet.ParameterSetName -eq "WithProxy") -and ($PSBoundParameters.ContainsKey('ProxyCredential') -eq $false)) {
                    $Users = Invoke-RestMethod -uri $Users.next -Proxy $Proxy -ProxyUseDefaultCredentials
                    
                } else {
                    $Users = Invoke-RestMethod -uri $Users.next -Proxy $Proxy -ProxyCredential $Proxycredential
                }
            }
            else {
                $MorePages = $false
            }
        } while ($MorePages) # Process the next page of data
    
        # The Deezer API gives a maximum of 300 results. Warn when this limit is reached.
        If ($Users.total -ge 300) {
            Write-Warning "Maximum number of objects reached (300), the result may be incomplete.`nTry a more specific search."
        }
    
    } # PROCESS
        
    END {} # END
        
} # Function