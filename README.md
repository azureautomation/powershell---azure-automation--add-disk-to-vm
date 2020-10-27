PowerShell + Azure Automation : Add Disk to VM
==============================================

            

The Azure Automation Workflow Script will add a new Data disk to an Azure VM and then use PowerShell Remoting and Storage cmdlets to Initialize the disk , Create a Partition and Format it seamlessly.



 


This came as a need to where we use Azure Automation to deploy VMs and then use this workflow to add data disks to it.

The Workflow utilizes 2 Azure Automation Credentials. 


  *  One to connect to your Azure Subscription

  *  Second one to open a PSSession to Azure and run Storage cmdlets



Have tried explaining the code bits at my Blog post below:



*[PowerShell + Azure Automation : Add-DataDisktoVM](http://www.dexterposh.com/2015/03/powershell-azure-automation-add-disk.html)*


 


Below is just the Workflow param declaration to give a sneek peak into it:



 
*
*




        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
