#!/usr/bin/perl

#SMART monitoring

########################################################################################
#
#
#
########################################################################################
#Далее ниже функция discovery которая сканирует все диски через SCSI порты /dev/sg и сопостовляет их в модели и серийные номера дисков.

sub discovery {
$first = 1;
$adaptec = 0;
$isWindows=`echo %OS%` eq "Windows_NT\n";

if ($isWindows) {
$scancommand="smartctl --scan";
} else
{
$scancommand="ls /dev/ |grep  -i -E '^(sg)'";
}

print "{\n";
print "\t\"data\":[\n\n";
$list="";
for (`$scancommand`) {
$smart_enabled=1;

if ($isWindows) {
$disk =substr($_, 0, index($_, " ") );
} else
{
$disk ="/dev/".$_;
chomp ($disk)}


@smartdata = `smartctl -i $disk`;
if ((grep{/QEMU/} @smartdata)or (grep{/Red Hat/} @smartdata) ){
last;
}

if (grep{/Adaptec/} @smartdata) {$adaptec = 1;$adaptecdisk=$disk;}

if (not (grep{/RAID/} @smartdata)&not (grep{/Promise/} @smartdata)&not (grep{/DVD/} @smartdata)&not (grep{/Virtual/} @smartdata)& not (grep{/Raid/} @smartdata)& not(grep{/Adaptec/} @smartdata) ){

if (grep {/SMART support is:     Disabled/} @smartdata){
`smartctl -i $disk -s on -o on -S on`;
}
$serial=(grep{/Serial/} @smartdata)[0];
chomp($serial);
$serial=~ s/ //g;
$serial=substr($serial, index($serial, ":")+1,length($serial));
$model=(grep{/Device Model/} @smartdata)[0];
$model=~ s/     //g;
chomp($model);
if ($model eq "" ){
$model=(grep{/Product:/} @smartdata)[0];
$model=~ s/              //g;
chomp $model;
}
$model=substr($model, index($model, ":")+1,length($model));
if (index($list,$serial) <0) {
    print "\t,\n" if not $first;
    print "\t{\n";
#print $disk;
    print "\t\t\"{#DISK_MODEL}\":\"$model\",\n";
    print "\t\t\"{#DISK_NAME}\":\"$disk\",\n";
    print "\t\t\"{#DISK_SERIAL}\":\"$serial\",\n";
    print "\t\t\"{#SMART_ENABLED}\":\"$smart_enabled\"\n";
    print "\t}\n";
$list=$list." ".$serial;
$first = 0;
}
}
}

if (($adaptec=1) & ($isWindows=1)) {
for ($i = 0; $i <=7; $i++){
$smart_enabled=1;
@smartdata = `smartctl64 -d sat,auto+aacraid,0,0,$i -i $disk`;

if (grep{/=== START OF/} @smartdata) {
if (grep {/SMART support is:     Disabled/} @smartdata){
`smartctl64 -d sat,auto+aacraid,0,0,$i -i $disk -s on -o on -S on`;
}

$serial=(grep{/Serial/} @smartdata)[0];
chomp($serial);
$serial=~ s/ //g;
$serial=substr($serial, index($serial, ":")+1,length($serial));
$model=(grep{/Device Model/} @smartdata)[0];
$model=~ s/     //g;
chomp($model);
if ($model eq "" ){
$model=(grep{/Product:/} @smartdata)[0];
$model=~ s/              //g;
chomp $model;
}
$model=substr($model, index($model, ":")+1,length($model));
if (index($list,$serial) <0) {
    print "\t,\n" if not $first;
    print "\t{\n";
    print "\t\t\"{#DISK_MODEL}\":\"$model\",\n";
    print "\t\t\"{#DISK_SERIAL}\":\"$serial\",\n";
    print "\t\t\"{#SMART_ENABLED}\":\"$smart_enabled\"\n";
    print "\t}\n";
$list=$list." ".$serial;
$first = 0;
}
}

}

};
print "\n\t]\n";
print "}\n";
};

########################################################################################
#
#
#
########################################################################################

#Функция вывода статуса состояния диска.
sub health  {



$isWindows=`echo %OS%` eq "Windows_NT\n";
if ($isWindows) {
$scancommand="smartctl --scan";
} else
{
$scancommand="ls /dev/ |grep  -i -E '^(sg)'";
}

for (`$scancommand`) {

$disk =substr($_, 0, index($_, " ") );
#print $disk;
@smartdata = `smartctl -i /dev/$disk`;
if (grep{/@_[0]/} @smartdata){
$health= `smartctl -H /dev/$disk || true` ;
print $health;

}
}


#if (($adaptec=1) & ($isWindows=1)) {
#for ($i = 0; $i <=7; $i++){

#@smartdata = `smartctl64 -d sat,auto+aacraid,0,0,$i -i $disk`;

#if (grep{/=== START OF/} @smartdata) {

#	if (grep{/@_/} @smartdata){
#		@smartdata = `smartctl64 -d sat,auto+aacraid,0,0,$i -a $disk`;
#		$passed=(grep{/SMART Health Status: OK/} @smartdata);
#		print $passed;
#		exit;
#	}

#}
#}
#};
};

########################################################################################
#
#
#
########################################################################################

# Функция выводите все атрибуты состояния SMART
sub raw  {
$isWindows=`echo %OS%` eq "Windows_NT\n";
if ($isWindows) {
$scancommand="smartctl --scan";
} else
{
$scancommand="ls /dev/ |grep  -i -E '^(sg)'";
}

for (`$scancommand`) {

$disk =substr($_, 0, index($_, " ") );
#print $disk;
@smartdata = `smartctl -i /dev/$disk`;
if (grep{/@_[0]/} @smartdata){
$raw_data= `smartctl -A /dev/$disk` ;
print $raw_data;
exit;
}}
print "0";
};

########################################################################################
#
#
#
########################################################################################

# Функция выводите все атрибуты состояния SMART
sub access  {

$access= `smartctl -i @_` ;
print $access;
exit;
};

########################################################################################
#
#
########################################################################################
#
#
########################################################################################

$param=@ARGV[0];
if ( $param eq "discovery" )	{discovery();exit 0;}
if ( $param eq "raw" )		{raw(@ARGV[1]);exit 0;}
if ( $param eq "health" )	{health(@ARGV[1]);exit 0;}
if ( $param eq "access" )	{access(@ARGV[1]);exit 0;}
if ( $param eq "smart_version" )	{print "5";exit 0;}

print "error?";
exit;


#https://github.com/paultrost/Disk-SMART-Perl/blob/master/lib/Disk/SMART.pm


