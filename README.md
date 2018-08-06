# Create a new Azure virtual machine with SQL image and join into an existing AD Domain

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3a%2f%2fraw.githubusercontent.com%2fGaveaInvest%2fGavea-DR-SQL%2fmaster%2fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3a%2f%2fraw.githubusercontent.com%2fGaveaInvest%2fGavea-DR-SQL%2fmaster%2fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/AzureGov.png"/>
</a>

This template allows you to create a new Azure virtual machine with SQL image and join into an existing Windows Active Directory Domain.

For this template to work we need the following prerequisites to be met:

1. An Active Directory Forest must exist and a Domain Controller must be accessible by the virtual machine either on-premises or in Azure
2. The user that is required in this template must have the necessary rights to join computers to an Active Directory Domain
3. Domain DNS Name must be resolved by the virtual machine

Details about some of the parameters:

1. existingVNETName - current location of the exising virtual machine. E.g. West US.
2. existingSubnetName
3. vmSize
4. domainToJoin
5. domainUsername - this parameter must be in username notation, E.g. myAdmin
6. domainPassword
7. domainJoinOptions
8. vmAdminUsername
9. vmAdminPassword
10. dnsLabelPrefix
4. ouPath - This is an optional parameter that allows you to join this virtual machine into a specific OU instead of the default Computers container. E.g. OU=MyCorpComputers,DC=Contoso,DC=com

