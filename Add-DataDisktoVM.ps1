Workflow Add-DataDisktoVM 
{ 
    Param 
    ( 
        #Specify the name of the Azure Subscription
        [parameter(Mandatory=$true)] 
        [String] 
        $AzureSubscriptionName, 
        
        #Specify the Cloud Service in which the Azure VM resides 
        [parameter(Mandatory=$true)] 
        [String] 
        $ServiceName, 
        
        #Key in the Storage Account to be used 
        [parameter(Mandatory=$true)] 
        [String]
        $StorageAccountName,
         
        #Supply the Azure VM name to which a Data Disk is to be added
        [parameter(Mandatory=$true)] 
        [String] 
        $VMName,   
        
        #Specify the name of Automation Credentials to be used to connect to the Azure VM
        [parameter(Mandatory=$true)] 
        [String] 
        $VMCredentialName, 
        
        #Specify the name of the Automation Creds to be used to authenticate against Azure
        [parameter(Mandatory=$true)] 
        [String] 
        $AzureCredentialName, 
         
        #Specify the Size in GB for the Data Disk to be added to the VM
        [parameter(Mandatory=$true)] 
        [int] 
        $sizeinGB,

        #Optional - Key in the Disk Label
        [parameter()]
        [string]$DiskLabel
    ) 

    $verbosepreference = 'continue'
        
    #Get the Credentials to authenticate against Azure
    Write-Verbose -Message "Getting the Credentials"
    $AzureCred = Get-AutomationPSCredential -Name $AzureCredentialName
    $VMCred = Get-AutomationPSCredential -Name $VMCredentialName
    
    #Add the Account to the Workflow
    Write-Verbose -Message "Adding the AuthAzure Account to Authenticate" 
    Add-AzureAccount -Credential $AzureCred
    
    #select the Subscription
    Write-Verbose -Message "Selecting the $AzureSubscriptionName Subscription"
    Select-AzureSubscription -SubscriptionName $AzureSubscriptionName
    
    #Set the Storage for the Subscrption
    Write-Verbose -Message "Setting the Storage Account for the Subscription" 
    Set-AzureSubscription -SubscriptionName $AzureSubscriptionName -CurrentStorageAccountName $StorageAccountName
     
    if (! $DiskLabel)
    {
        $DiskLabel = $VMName #set the DiskLabel as the VM name if not passed
    }
    
    #Get the WinRM URI , used later to open a PSSession
    Write-Verbose -Message "Getting the WinRM URI for the $VMname"
    $WinRMURi = Get-AzureWinRMUri -ServiceName $ServiceName -Name $VMName | Select-Object -ExpandProperty AbsoluteUri
   
    #Get the LUN details of any Data Disk associated to the Azure VM, Had to wrap this inside InlineScript
    Write-Verbose -Message "Getting details of the LUN added to the VMs"
    $Luns =  InlineScript {
                Get-AzureVM -ServiceName $using:ServiceName -Name $using:VMName |
                    Get-AzureDataDisk | 
                    select -ExpandProperty LUN
             }
    #Depending on whether the Azure VM already has DATA Disks attached, need to calculate a LUN
    if ($Luns)
    {
        
        Write-Verbose -Message "Generating a random LUN number to be used"
        $Lun = 1..100 | where {$Luns -notcontains $_} | select -First 1
    }
    else
    {
        Write-Verbose -Message "No Data Disks found attached to VM"
        $Lun = 1
    }

    #Finally add the Data Disk to Azure VM, again this needs to be put inside InlineScript block
    Write-Verbose -Message "Adding the Data Disk to the Azure VM using DiskLabel -> $DiskLabel ; LUN -> $Lun ; SizeinGB -> $sizeinGB"
    InlineScript {
        Get-AzureVM -ServiceName $using:ServiceName -Name $using:VMName | 
            Add-AzureDataDisk -CreateNew -DiskSizeInGB $using:sizeinGB -DiskLabel $using:DiskLabel -LUN $using:Lun  | 
            Update-AzureVM
        }


    # Open a PSSession to the Azure VM and then attach the Disk 
    #using the Storage Cmdlets (Usually Server 2012 images are selected which have this module) 
    InlineScript 
    {   
        do
        {
            #open a PSSession to the VM
            $Session = New-PSSession -ConnectionUri $Using:WinRMURi -Credential $Using:VMCred -Name $using:VMName -SessionOption (New-PSSessionOption -SkipCACheck ) -ErrorAction SilentlyContinue 
            Write-Verbose -Message "PSSession opened to the VM $Using:VMName "
        } While (! $Session)
        
        Write-Verbose -Message "Invoking command to Initialize/ Create / Format the new Disk added to the Azure VM"     
        Invoke-command -session $session -argumentlist $using:DiskLabel -ScriptBlock { 
            param($label)
            Get-Disk |
            where partitionstyle -eq 'raw' |
            Initialize-Disk -PartitionStyle MBR -PassThru |
            New-Partition -AssignDriveLetter -UseMaximumSize |
            Format-Volume -FileSystem NTFS -NewFileSystemLabel $label -Confirm:$false
        } 
 
    } 
     
    
}


