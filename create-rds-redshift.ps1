#https://github.com/key2market/Live-data-streaming-from-RDS-Postgres-to-Redshift
Param(
    [Parameter(Mandatory = $true)][string]$param_file
 )

# Parse the parameter ini file
Get-Content "$param_file" | ForEach-Object -Begin {$settings=@{}} -Process {$store = [regex]::split($_,'='); if(($store[0].CompareTo("") -ne 0) -and ($store[0].StartsWith("[") -ne $True) -and ($store[0].StartsWith("#") -ne $True)) {$settings.Add($store[0], $store[1])}}
$StageAccountProfile = $settings.Get_Item("StageAccountProfile")
$S3Bucket = $settings.Get_Item("S3Bucket")
$AvailabilityZone = $settings.Get_Item("AvailabilityZone")
$LambdaSubnetCIDR = $settings.Get_Item("LambdaSubnetCIDR")
$Vpc = $settings.Get_Item("Vpc")
$DatabaseSG = $settings.Get_Item("DatabaseSG")
$DatabaseHost = $settings.Get_Item("DatabaseHost")
$DatabaseMasterPassword = $settings.Get_Item("DatabaseMasterPassword")
$DatabaseMasterUsername = $settings.Get_Item("DatabaseMasterUsername")
$DatabaseName = $settings.Get_Item("DatabaseName")
$DatabasePort = $settings.Get_Item("DatabasePort")
$LogicalReplicationSlotName = $settings.Get_Item("LogicalReplicationSlotName")

# Ensure all parameters are populated
While (!$StageAccountProfile) {
    $StageAccountProfile = Read-Host "StageAccountProfile is required"
}
While (!$S3Bucket) {
    $S3Bucket = Read-Host "S3Bucket is required"
}
While (!$AvailabilityZone) {
    $AvailabilityZone = Read-Host "AvailabilityZone is required"
}
While (!$LambdaSubnetCIDR) {
    $LambdaSubnetCIDR = Read-Host "LambdaSubnetCIDR is required"
}
While (!$Vpc) {
    $Vpc = Read-Host "Vpc is required"
}
While (!$DatabaseSG) {
    $DatabaseSG = Read-Host "DatabaseSG is required"
}
While (!$DatabaseHost) {
    $DatabaseHost = Read-Host "DatabaseHost is required"
}
While (!$DatabaseMasterPassword) {
    $DatabaseMasterPassword = Read-Host "DatabaseMasterPassword is required"
}
While (!$DatabaseMasterUsername) {
    $DatabaseMasterUsername = Read-Host "DatabaseMasterUsername is required"
}
While (!$DatabaseName) {
    $DatabaseName = Read-Host "DatabaseName is required"
}
While (!$DatabasePort) {
    $DatabasePort = Read-Host "DatabasePort is required"
}
While (!$LogicalReplicationSlotName) {
    $LogicalReplicationSlotName = Read-Host "LogicalReplicationSlotName is required"
}

$StageAccountProfile = $settings.Get_Item("StageAccountProfile")
$S3Bucket = $settings.Get_Item("S3Bucket")
$AvailabilityZone = $settings.Get_Item("AvailabilityZone")
$LambdaSubnetCIDR = $settings.Get_Item("LambdaSubnetCIDR")
$Vpc = $settings.Get_Item("Vpc")
$DatabaseSG = $settings.Get_Item("DatabaseSG")
$DatabaseHost = $settings.Get_Item("DatabaseHost")
$DatabaseMasterPassword = $settings.Get_Item("DatabaseMasterPassword")
$DatabaseMasterUsername = $settings.Get_Item("DatabaseMasterUsername")
$DatabaseName = $settings.Get_Item("DatabaseName")
$DatabasePort = $settings.Get_Item("DatabasePort")
$LogicalReplicationSlotName = $settings.Get_Item("LogicalReplicationSlotName")

Clear-Host
Write-Host "This script will create a lambda to pull changes from the Postgresql WAL logs:"
Write-Host ""
Write-Host "   StageProfile:                 $StageAccountProfile"
Write-Host "   S3Bucket:                     $S3Bucket"
Write-Host "   AvailabilityZones:            $AvailabilityZone"
Write-Host "   LambdaSubnetCIDR:             $LambdaSubnetCIDR"
Write-Host "   Vpc:                          $Vpc"
Write-Host "   DatabaseSG:                   $DatabaseSG"
Write-Host "   DatabaseHost:                 $DatabaseHost"
Write-Host "   DatabaseMasterPassword:       $DatabaseMasterPassword"
Write-Host "   DatabaseMasterUsername:       $DatabaseMasterUsername"
Write-Host "   DatabaseName:                 $DatabaseName"
Write-Host "   DatabasePort:                 $DatabasePort"
Write-Host "   LogicalReplicationSlotName:   $LogicalReplicationSlotName"
Write-Host ""
Write-Host "Press [enter] to continue (Ctrl+C to exit)" -NoNewline
Read-Host

# Run npm install
Write-Host "Restoring packages"
npm install

# Run npm run webpack
Write-Host "Packaging webpack"
npm run webpack

# TODO Create S3 Bucket
Write-Host "Ensure the S3 Bucket $S3Bucket is created before proceeding (press any key to continue)" -ForegroundColor Red
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

# Upload the lambda packages to a S3 bucket, replace the bucket name
Write-Host "Packaging template" -ForegroundColor White
aws cloudformation package --template-file ./src/template/rds-lambda.yform --s3-bucket $S3Bucket --output-template-file ./rds-lambda.yaml

# Deploy template
aws cloudformation deploy --stack-name rds-redshift-copy --template-file ./rds-lambda.yaml --parameter-overrides AvailabilityZones=$AvailabilityZone LambdaSubnet0CIDR=$LambdaSubnetCIDR Vpc=$Vpc DatabaseSG=$DatabaseSG DatabaseHost=$DatabaseHost DatabaseMasterPassword=$DatabaseMasterPassword DatabaseMasterUsername=$DatabaseMasterUsername DatabaseName=$DatabaseName DatabasePort=$DatabasePort LogicalReplicationSlotName=$LogicalReplicationSlotName --capabilities=CAPABILITY_IAM --profile=$StageAccountProfile
#Write-Host "Manually deploy the template rds-lambda.yaml through the console and enable port 5432 outbound from the Lambda security group to the RDS security group (press any key to continue)" -ForegroundColor Red
#$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
