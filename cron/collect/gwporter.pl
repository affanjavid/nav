#!/usr/bin/perl

use strict;

require "/usr/local/nav/navme/etc/conf/path.pl";
my $lib = &lib();
my $localkilde = &localkilde();
require "$lib/database.pl";
require "$lib/snmplib.pl";
require "$lib/fil.pl";
require "$lib/iplib.pl";
my $debug = 0;

my $ip2IfIndex     = ".1.3.6.1.2.1.4.20.1.2"; 
my $ip2NetMask     = ".1.3.6.1.2.1.4.20.1.3"; 
my $ip2ospf        = ".1.3.6.1.2.1.14.8.1.4";
my $ifType         = ".1.3.6.1.2.1.2.2.1.3";
my $if2AdminStatus = ".1.3.6.1.2.1.2.2.1.7";
my $if2Descr       = ".1.3.6.1.2.1.2.2.1.2";
my $if2Speed       = ".1.3.6.1.2.1.2.2.1.5";
my $ifInOctet      = ".1.3.6.1.2.1.2.2.1.10";
my $ifAlias        = ".1.3.6.1.2.1.31.1.1.1.18";
my $hsrp_status    = ".1.3.6.1.4.1.9.9.106.1.2.1.1.15";
my $hsrp_rootgw    = ".1.3.6.1.4.1.9.9.106.1.2.1.1.11";

my $db = &db_connect("manage","navall","uka97urgf");

## antmask tatt ut
my @felt_prefiks =("prefiksid","nettadr","maske","vlan","maxhosts","nettype","orgid","anvid","nettident","samband","komm");
my @felt_gwport = ("gwportid","boksid","ifindex","gwip","interf","masterindex","speed","ospf");

my (%lan, %stam, %link, %vlan);
&fil_vlan;

my $fil_prefiks = "$localkilde/prefiks.txt";
my @felt_fil_prefiks = ("nettadr","maske","nettype","orgid","komm");
my %prefiks = &fil_prefiks($fil_prefiks,scalar(@felt_fil_prefiks));

my %prefiksid = &db_hent_dobbel($db,"SELECT nettadr,maske,prefiksid FROM prefiks");
my %bokser = &db_hent_hash($db,"SELECT boksid,ip,sysName,watch,ro FROM boks WHERE kat=\'GW\'");

my %boks2prefiks;
# my %prefiks; definert i fillesinga fra prefiks.txt
my %db_prefiks = &db_select_hash($db,"prefiks",\@felt_prefiks,1,2);

my %gwport;
my %db_gwport = &db_select_hash($db,"gwport",\@felt_gwport,1,2,3);

#foreach my $boksid (keys %bokser){
#    print $bokser{$boksid}[1].$bokser{$boksid}[2]."\n";
#}

foreach my $boksid (keys %bokser) { #$_ = boksid keys %boks
    if($bokser{$boksid}[3] =~ /y|t/i) {
	&skriv("DEVICE-WATCH","ip=".$bokser{$boksid}[2]);
    } else {
	if ( &hent_snmpdata($bokser{$boksid}[1],$bokser{$boksid}[4],$boksid) eq '0' ) {
	    &skriv("DEVICE-BOXDOWN","ip=".$bokser{$boksid}[2]);
	}
    }
}

#for my $nettadr ( keys %prefiks ) {
#    print "\nboks".$boks;
#    for my $maske (keys %{$prefiks{$nettadr}}) {
#	print "\nifindex".$ifindex;
#	&db_manipulate($db,1,"prefiks",\@felt_prefiks,\@{$prefiks{$nettadr}{$maske}},\@{$db_prefiks{$nettadr}{$maske}},$nettadr,$maske);
#    }
#}
print "***********************************************";

&db_alt($db,2,0,"prefiks",\@felt_prefiks,\%prefiks,\%db_prefiks,[1,2]);

#n� som alle prefiksene er samlet inn, vil det v�re p� sin plass � sette dem inn i boks.

my %nettadr2prefiksid = &db_hent_enkel($db,"SELECT nettadr,prefiksid FROM prefiks");

&oppdater_prefiks($db,"boks","ip","prefiksid");

#oppdaterer gwport, men tar ikke med prefiksid i denne omgang. Det m� gj�res seinere fordi det ikke er snmpinnsamlinga skjedde samtidig med prefiks, og da var det ikke noe prefiksid � f� tak i.
#for my $boks ( keys %gwport ) {
#    for my $ifindex (keys %{$gwport{$boks}}) {
#	for my $gwip (keys %{$gwport{$boks}{$ifindex}}) {
#	    for my $innhold (@{$db_gwport{$boks}{$ifindex}{$gwip}}) {
#		print "$innhold|";
#	    }
#	    &db_manipulate($db,1,"gwport",\@felt_gwport,\@{$gwport{$boks}{$ifindex}{$gwip}},\@{$db_gwport{$boks}{$ifindex}{$gwip}},$boks,$ifindex,$gwip);
#	}
#    }
#}

&db_alt($db,3,0,"gwport",\@felt_gwport,\%gwport,\%db_gwport,[1,2,3]);


#prefiksid i gwport oppdateres her
&oppdater_prefiks($db,"gwport","gwip","prefiksid");

my %prefiksid2rootgwid = &db_hent_enkel($db,"SELECT prefiksid,rootgwid FROM prefiks");
my %gwip2gwportid = &db_hent_enkel($db,"SELECT gwip,gwportid FROM gwport");
my %prefiksid2gwip =  &db_hent_enkel($db,"select prefiksid,min(gwip) from gwport natural join prefiks where nettadr < gwip group by prefiksid");

foreach my $prefiksid (keys %prefiksid2gwip) {
    my $gammel = $prefiksid2rootgwid{$prefiksid};
    my $ny = $gwip2gwportid{$prefiksid2gwip{$prefiksid}};
    unless ($ny eq $gammel) {
	&db_update($db,"prefiks","rootgwid",$gammel,$ny,"prefiksid=$prefiksid");
    }
}
## Setter antmask. Dette skjer til slutt. Det er dumt, det kunne v�rt
## gjort underveis.
my %antmask = &db_hent_enkel($db,"select prefiksid,count(distinct mac) from arp where date_part('days',cast(NOW()-fra as INTERVAL)) <7 or til ='infinity' group by prefiksid");
my %db_antmask = &db_hent_enkel($db,"select prefiksid,antmask from prefiks");
foreach my $prefiksid (keys %db_antmask) {
    my $gammel = $db_antmask{$prefiksid};
    my $ny;
    unless($ny = $antmask{$prefiksid}){
	$ny = '';
    }
    unless ($ny eq $gammel) {
	&db_update($db,"prefiks","antmask",$gammel,$ny,"prefiksid=$prefiksid");
    }
}

######################################
sub snmp_ruter{
    my $host = $_[0];
    my $community = $_[1];
    my $boksid = $_[2];
    my %prefiks;
    my %gatewayif;

    my $debug = 1;

    print "skal teste $host" if $debug;

    my $sess = new SNMP::Session(DestHost => $host, Community => $community, Version => 2, UseNumeric=>1, UseLongNames=>1);
    print $sess->{ErrorStr};

   if(my $numInts = $sess->get('ifNumber.0')){ #ver 2


    &skriv("SNMP-ERROR","message=".$sess->{ErrorStr},"ip=$host");

    my ($ifindex,$netmask,$type,$status,$description,$speed,$inoctet,$alias,$hsrpstatus,$hsrprootgwid) = $sess->bulkwalk(0,$numInts+1,[['.1.3.6.1.2.1.4.20.1.2'],['.1.3.6.1.2.1.4.20.1.3'],['.1.3.6.1.2.1.2.2.1.3'],['.1.3.6.1.2.1.2.2.1.7'],['.1.3.6.1.2.1.2.2.1.2'],['.1.3.6.1.2.1.2.2.1.5'],['.1.3.6.1.2.1.2.2.1.10'],['.1.3.6.1.2.1.31.1.1.1.18'],['.1.3.6.1.4.1.9.9.106.1.2.1.1.15'],['.1.3.6.1.4.1.9.9.106.1.2.1.1.11']]);

    my ($ospf) = $sess->bulkwalk(0,$numInts+1,[['.1.3.6.1.2.1.14.8.1.4']]);

  
    my @ospf2;
    my $i = 0;
    for my $o (@{$ospf}){
#	print $$o[0]."   ". $$o[1]."   ". $$o[2]."\n";
	if($$o[1] == 0){
	    $ospf2[$i] = $$o[2];
	    $i++;
	}
    }

    my @hsrp;
    for my $h (@{$hsrprootgwid}){
	$$h[0] =~ /\.(\d+)$/;
	$hsrp[$1] = $$h[2];
    }

    my(@speed2,@inoctet2,@type2,@status2,@description2,@alias2);

    my $i = 0;
    while ($$speed[$i]){
	$speed2[$$speed[$i][1]] = $$speed[$i][2];
	$inoctet2[$$inoctet[$i][1]] = $$inoctet[$i][2];
	$type2[$$type[$i][1]] = $$type[$i][2];
	$description2[$$description[$i][1]] = $$description[$i][2];
	$status2[$$status[$i][1]] = $$status[$i][2];
	$alias2[$$alias[$i][1]] = $$alias[$i][2];
	$i++;
    }
  
    my $i = 0;
    while ($$ifindex[$i]){
	
	$$ifindex[$i][0] =~ /(\d+\.\d+\.\d+)$/;

	my $gwip = $1.'.'.$$ifindex[$i][1];
	my $interface = $$ifindex[$i][2];
	my $netmask = $$netmask[$i][2];
	my $nettadr = &and_ip($gwip,$netmask);
	my $maske = &mask_bits($netmask);
	my $prefiksid = &hent_prefiksid($nettadr,$maske);

	my $status = $status2[$interface];
	my $type = $type2[$interface];
	my $hsrp = $hsrp[$interface];
	my $octet = $inoctet2[$interface];
	my $nettnavn = $alias2[$interface];
	my $description = $description2[$interface];
	my $ospf = $ospf2[$i+1];

	my $speed = $speed2[$interface];
	$speed  = ($speed/1e6);
	$speed =~ s/^(.{0,10}).*/$1/;

#	print $$description[$i][0]."   ".$$description[$i][1]."   ".$$description[$i][2]."\n";

#	print $gwip."   ".$description;
#	print $ospf2[$i+1];

#	print $hsrp[$interface];

	print $gwip."   ".$interface."   ".$speed."   ".$status."   ".$octet."   ".$type."   ".$description."   ".$nettnavn."   ".$maske."   ".$hsrp;

	print "\n";

	if($status == 1 && $type != 23){
	    if($octet && !$gwip){
		print "skal legge ut med tom gwip\n";
	    }
	}

	if($status == 1 && $type != 23){
	    print "ok: ".$host."    ".$gwip."   ".$interface."   ".$speed."   ".$status."   ".$octet."   ".$type."   ".$description."   ".$nettnavn."   ".$maske."   ".$hsrp."\n";
	}

	my $maxhosts = &max_ant_hosts($maske);

	$_ = &rydd($nettnavn);
	unless(/^(?:lan|stam|link|elink)/i || $description =~ /loopback/i) {
	    $_ = &rydd($vlan{$nettadr}{$maske});
	}
	(my $vlan,my $noe, my $noeannet) = &finn_vlan($_,$boksid);

	if(/^(?:lan|stam)/i) {
	    my $nettnavn = $_;
	    my ($nettype,$org,$anv,$komm) = split /,/;
	    $nettype = &rydd($nettype);
	    $nettype =~ s/lan(\d*)/lan/i;
#	    $nettype = "lan";
	    $org = &rydd($org);
	    $org =~ s/^(\w*?)\d*$/$1/;
	    $anv = &rydd($anv);
	    $anv =~ s/^(\w*?)\d*$/$1/;
	    $nettnavn =~ s/^.+?\,(.+?\,.+?)(\,.*)?$/$1/i;
#	    print "\n $nettadr / $maske";
	    $prefiks{$nettadr}{$maske} = [ undef, $nettadr, $maske, 
					   $vlan,  $maxhosts, 
					   $nettype,$org,$anv,
					   $nettnavn, undef,$komm];


	} elsif (/^link/i) {
#	    print;
	    my ($nettype,$samband,$komm) = split /,/;
	    my $nettident = "$noe,$noeannet";
	    $prefiks{$nettadr}{$maske} = [ undef, $nettadr, $maske,
					   $vlan,  $maxhosts,
					   $nettype, undef, undef,
					   $nettident, $samband, $komm];

} elsif (/^elink/i) {
#	    print;
	    my ($nettype,$ruter,$org,$samband,$komm) = split /,/;
#	    print "   ruter-".$ruter;
	    my $nettident = "$noe,$noeannet";
#	    print "   nettident-".$nettident;
	    $prefiks{$nettadr}{$maske} = [ undef, $nettadr, $maske,
					   $vlan,  $maxhosts,
					   $nettype, $org, undef,
					   $nettident, $samband, $komm]; #ruter tatt over for samband. Egentlig skulle ruter hatt et eget tilruter.

	} elsif ($description =~ /loopback/i) {
#	    print "har funnet loopback";
	    my $nettype = "loopback";
	    $prefiks{$nettadr}{$maske} = [ undef, $nettadr, $maske,
					   $vlan,  $maxhosts,
					   $nettype, undef, undef,
					   undef, undef, undef ];
	}else {
#	    print "har funnet ukjent $_";
	    my $nettype = "ukjent";
	    if($prefiks{$nettadr}{$maske}[8]){
		&skriv("DEBUG-NOOVRWRT", "prefix=".$prefiks{$nettadr}{$maske}[8]);
	    } else {
		$prefiks{$nettadr}{$maske} = [ undef, $nettadr, $maske,
					       $vlan,  $maxhosts,
					       $nettype, undef, undef,
					       undef, undef, undef ];
	    }
	}
	
	
	

	
	$i++;

    }
} else {
    print "$host ver1";
}
}


sub hent_snmpdata {
    my $ip = $_[0];
    my $ro = $_[1];
    my $boksid = $_[2];

    my %interface = ();
    my %gatewayip = ();
    my %id;
    my %boks;

    my @ifindex = &snmpwalk("$ro\@$ip",$ip2IfIndex);
    return(0) unless $ifindex[0];
    foreach my $line (@ifindex) {
        (my $gwip,my $if) = split(/:/,$line);
#	print "\n$boksid:$if:gwip:",
	$interface{$if}{gwip} = $gwip;
	$gatewayip{$gwip}{ifindex} = $if;
    }
    my @alias = &snmpwalk("$ro\@$ip",$ifAlias);
    foreach my $line (@alias) {
        (my $if,my $nettnavn) = split(/:/,$line);
#	print "nettnavn $nettnavn\n\n";
	$interface{$if}{nettnavn} = $nettnavn;
    }    
    my @descr = &snmpwalk("$ro\@$ip",$if2Descr);
    my %description;
    foreach my $line (@descr) {
        (my $if,my $interf) = split(/:/,$line);
	$interface{$if}{interf} = $interf;
	my ($masterinterf,$subinterf) = split/\./,$interf;
	if($subinterf){
	    $interface{$if}{master} = $description{$masterinterf};
	} else {
	    $description{$masterinterf} = $if;
	}
    } 
    my @netmask = &snmpwalk("$ro\@$ip",$ip2NetMask);
    foreach my $line (@netmask)
    {
        (my $gwip,my $netmask) = split(/:/,$line);
	$gatewayip{$gwip}{netmask} = $netmask;
	$gatewayip{$gwip}{nettadr} = &and_ip($gwip,$netmask);
#	print "\n$gwip & $netmask = ".$gatewayip{$gwip}{nettadr};
	$gatewayip{$gwip}{maske} = &mask_bits($netmask);
	$gatewayip{$gwip}{prefiksid} = 
	    &hent_prefiksid($gatewayip{$gwip}{nettadr},
			    $gatewayip{$gwip}{maske});
#	print "\n";
#	print $gwip;
#	print "\n";
#	print $gatewayip{$gwip}{prefiksid};
    }
#over: prefiks& under: gwport
    my @speed = &snmpwalk("$ro\@$ip",$if2Speed);
    foreach my $line (@speed) {
        (my $if,my $speed) = split(/:/,$line);
	$speed = ($speed/1e6);
	$speed =~ s/^(.{0,10}).*/$1/; #tar med de 10 f�rste tegn fra speed
	$interface{$if}{speed} = $speed;
    }
    my @adminstatus = &snmpwalk("$ro\@$ip",$if2AdminStatus);
    foreach my $line (@adminstatus) {                                             
	(my $if,my $status) = split(/:/,$line); 
	$interface{$if}{status} = $status;
    }
    my @inoctet = &snmpwalk("$ro\@$ip",$ifInOctet);
    foreach my $line (@inoctet) {                                             
	(my $if,my $octet) = split(/:/,$line); 
	$interface{$if}{octet} = $octet;
#	$gatewayip{0.0.0.0}{ifindex} = $if;
    }    
    my @type = &snmpwalk("$ro\@$ip",$ifType);
    foreach my $line (@type) {                                             
	(my $if,my $type) = split(/:/,$line); 
	$interface{$if}{type} = $type;
    }
    my @ospf = &snmpwalk("$ro\@$ip",$ip2ospf);
    foreach my $line (@ospf) {
        (my $utv_ip,my $ospf) = split(/:/,$line);
        if ($utv_ip =~ /\.0\.0$/){
            my (@ip) = split(/\./,$utv_ip);
            my $gwip = "$ip[0].$ip[1].$ip[2].$ip[3]";
            if ($gatewayip{$gwip}{ifindex}){
		$gatewayip{$gwip}{ospf} = $ospf;
#	    print "OSPF $gwip\t$ospf\n";
	    }
        }
    }  
# hsrpgw-triksing
    my @hsrp = &snmpwalk("$ro\@$ip",$hsrp_status);
    foreach my $line (@hsrp) {
	(my $if,undef,my $hsrpstatus) = split(/:|\./,$line);    
	if($hsrpstatus == 6) {
	    if(my ($rootgwip) = &snmpget("$ro\@$ip",$hsrp_rootgw.".".$if.".0")){
#	    print "\n$boksid:$if:nhsrp:",
		$gatewayip{$rootgwip}{ifindex} = $if;
	    }
	}
    }


    foreach my $if ( keys %interface ) {
#	print $interface{$if}{status};
	if($interface{$if}{status} == 1 && $interface{$if}{type} != 23) {
	    if($interface{$if}{octet}&&!$interface{$if}{gwip}){
		$gwport{$boksid}{$if}{""} = [ undef,
					      $boksid,
					      $if,
					      undef,
					      $interface{$if}{interf},
					      $interface{$if}{master},
					      $interface{$if}{speed},
					      undef];
	    }
	}
    }
    foreach my $gwip ( keys %gatewayip ) {
#	print "$gwip\n";
	my $if = $gatewayip{$gwip}{ifindex};
#	print $interface{$if}{status};
	if($interface{$if}{status} == 1 && $interface{$if}{type} != 23) {
	    my $interf = $interface{$if}{interf};
	    my $ospf = $gatewayip{$gwip}{ospf};
#	print "m|".$interface{$if}{master}."|\n";
	    $gwport{$boksid}{$if}{$gwip} = [ undef,
					     $boksid,
					     $if,
					     $gwip,
					     $interf,
					     $interface{$if}{master},
					     $interface{$if}{speed},
					     $ospf];
	}
    }


    foreach my $gwip (keys %gatewayip)
    {
	my $if = $gatewayip{$gwip}{ifindex};
	my $nettadr = $gatewayip{$gwip}{nettadr};
	my $maske = $gatewayip{$gwip}{maske};
	my $netmask = $gatewayip{$gwip}{netmask};
#	my $nettadr = $gatewayip{$interface{$if}{gwip}}{nettadr};
#	my $maske = $gatewayip{$interface{$if}{gwip}}{maske};
#	my $netmask = $gatewayip{$interface{$if}{gwip}}{netmask};
	my $maxhosts = &max_ant_hosts($maske);
#	my $antmask= &ant_maskiner($interface{$if}{gwip},
#						  $netmask)
#						  $maxhosts);
#	$boks2prefiks{$boksid} = $id if $nettadr && $maske;

	my $interf = $interface{$if}{interf};
	$_ = &rydd($interface{$if}{nettnavn});
	unless (/^(?:lan|stam|link|elink)/i || $interf =~ /loopback/i) {
	    $_ = &rydd($vlan{$nettadr}{$maske});
	}
	(my $vlan,my $noe, my $noeannet) = &finn_vlan($_,$boksid);
	
	if(/^(?:lan|stam)/i) {
	    my $nettnavn = $_;
	    my ($nettype,$org,$anv,$komm) = split /,/;
	    $nettype = &rydd($nettype);
	    $nettype =~ s/lan(\d*)/lan/i;
#	    $nettype = "lan";
	    $org = &rydd($org);
	    $org =~ s/^(\w*?)\d*$/$1/;
	    $anv = &rydd($anv);
	    $anv =~ s/^(\w*?)\d*$/$1/;
	    $nettnavn =~ s/^.+?\,(.+?\,.+?)(\,.*)?$/$1/i;
#	    print "\n $nettadr / $maske";
	    $prefiks{$nettadr}{$maske} = [ undef, $nettadr, $maske, 
					   $vlan,  $maxhosts, 
					   $nettype,$org,$anv,
					   $nettnavn, undef,$komm];

#	} elsif (/^stam/i) {
#	    my ($nettype,$stamnavn,$komm) = split /,/;
#	    $prefiks{$nettadr}{$maske} = [ undef, $nettadr, $maske,
#					   $vlan,  $maxhosts,
#					   $nettype, undef, undef,
#					   $stamnavn, $komm];
	} elsif (/^link/i) {
#	    print;
	    my ($nettype,$samband,$komm) = split /,/;
	    my $nettident = "$noe,$noeannet";
	    $prefiks{$nettadr}{$maske} = [ undef, $nettadr, $maske,
					   $vlan,  $maxhosts,
					   $nettype, undef, undef,
					   $nettident, $samband, $komm];

	} elsif (/^elink/i) {
#	    print;
	    my ($nettype,$ruter,$org,$samband,$komm) = split /,/;
#	    print "   ruter-".$ruter;
	    my $nettident = "$noe,$noeannet";
#	    print "   nettident-".$nettident;
	    $prefiks{$nettadr}{$maske} = [ undef, $nettadr, $maske,
					   $vlan,  $maxhosts,
					   $nettype, $org, undef,
					   $nettident, $samband, $komm]; #ruter tatt over for samband. Egentlig skulle ruter hatt et eget tilruter.

	} elsif ($interf =~ /loopback/i) {
#	    print "har funnet loopback";
	    my $nettype = "loopback";
	    $prefiks{$nettadr}{$maske} = [ undef, $nettadr, $maske,
					   $vlan,  $maxhosts,
					   $nettype, undef, undef,
					   undef, undef, undef ];
	}
	else {
#	    print "har funnet ukjent $_";
	    my $nettype = "ukjent";
	    if($prefiks{$nettadr}{$maske}[8]){
		&skriv("PREFIX-NOOVRWRT", "prefix=".$prefiks{$nettadr}{$maske}[8]);
	    } else {
	    $prefiks{$nettadr}{$maske} = [ undef, $nettadr, $maske,
					   $vlan,  $maxhosts,
					   $nettype, undef, undef,
					   undef, undef, undef ];
	}
	}

    }
}



 


sub fil_vlan{
open VLAN, "<$localkilde/vlan.txt";
foreach (<VLAN>){ #peller ut vlan og putter i nettypehasher
#    print "\nlinje :: $_ \n";
    if(/^(\d+)\:((?:lan|stam|link)\,(\S+?)\,(\S+?))(?:\,\S+?)??(?:\:(\S+?)\/(\d+))??\s*(?:\#.*)??$/) {
	$lan{$3}{$4} = $1;
#	print "linje: $4\n";
#	$vlan{$5}{$6} = $2;
#    } elsif (/^(\d+)\:(stam\,(\S+?))(?:\,\S+?)??(?:\:(\S+?)\/(\d+))??\s*\#.*$/) {
#	$stam{$3} = $1;
#	print "heeeeeeeeeeeeeeeei $3   $2    $1\n";
#	$vlan{$4}{$5} = $2;
#    } elsif (/^(\d+)\:(link\,(\S+?)\,(\S+?)(?:\,\S+?)??)(?:\:(\S+?)\/(\d+))??\s*\#.*$/) {
#	$link{$3}{$4} = $1;
#	$vlan{$5}{$6} = $2;
#    } elsif (/^(\d+)\:elink\,(\S+?)\,(\S+?)(?:\,\S+?)??(?:\:(.*?))??\#.*?$/) {
#	$elink{$2}{$3} = $1;
#	$vlan{$1} = ($5);
#    } else {
#	print "kommentar: $_";
    }
#    print "\n$1:$2:$3";    
}
close VLAN;
=cut
    open VLAN, "<$localkilde/vlan.txt";
    foreach (<VLAN>){ #peller ut vlan og putter i nettypehasher
	print;
	if(/^(\d+)\:lan\,(\S+?)\,(\S+?)$/) {
	    $lan{$2}{$3} = $1;
	    print "\n".$lan{$2}{$3};
	} elsif (/^(\d+)\:stam\,(\S+?)$/) {
	    $stam{$2} = $1;
	    print "\n".$stam{$2};
	} elsif (/^(\d+)\:link\,(\S+?)\,(\S+?)$/) {
	    $link{$2}{$3} = $1;
	    print "\n".$link{$2}{$3};
	} else {
	    print "\ngikk feil: $_";
	}
#	print "\n$1:$2:$3";    
    }
    close VLAN;
=cut
}
sub finn_vlan
{
    my $vlan = "";
    my ($boks,undef) = split /\./,$bokser{$_[1]}[2],2;
    $_ = $_[0];
    if(/^(?:lan|stam)\d*\,(\S+?)\,(\S+?)(?:\,|$)/i) {
	$vlan = $lan{$1}{$2};
#    } elsif(/^stam\,(\S+?)$/i) {
#	$vlan = $stam{$1};
    }elsif(/^e?link\,(\S+?)(?:\,|$)/i) {
	if (defined($boks)){
	    $vlan = $lan{$1}{$boks} || $lan{$boks}{$1};
#	    print "\n:$vlan:$1:$boks";
#	    return ($boks,$1,$vlan)
	}
    }
    return ($vlan,$boks,$1);
}

sub hent_prefiksid {
    my ($nettadr,$maske) = @_;
    return $prefiksid{$nettadr}{$maske};
}
sub max_ant_hosts
{
    return 0 unless(defined($_[0]));
    return 0 if($_[0] == 0);
    return(($_ = 2**(32-$_[0])-2)>0 ? $_ : 0);
} 
sub ant_maskiner {
    my $prefiksid = $_[0];
    return $antmask{$prefiksid};
}

sub finn_prefiksid {
    # Tar inn ip, splitter opp og and'er med diverse
    # nettmasker. M�let er � finne en match med en allerede innhentet
    # prefiksid (hash over alle), som s� returneres.
    my $ip = $_[0];
    my @masker = ("255.255.255.255","255.255.255.254","255.255.255.252","255.255.255.248","255.255.255.240","255.255.255.224","255.255.255.192","255.255.255.128","255.255.255.0","255.255.254.0","255.255.252.0");
    foreach my $maske (@masker) {
	my $nettadr = &and_ip($ip,$maske);
#	print "\n_".$ip."_".$maske."_".$nettadr;
#	print "$ip & $maske = $nettadr\n";
	return $nettadr2prefiksid{$nettadr} if (defined $nettadr2prefiksid{$nettadr});
    }
    # print "Fant ikke prefiksid for $ip\n";
    return 0;
}

sub oppdater_prefiks{
    my ($db,$tabell,$felt_fast,$felt_endres) = @_;
    my %iper = &db_hent_enkel($db,"SELECT $felt_fast,$felt_endres FROM $tabell");
    foreach my $ip (keys %iper) {
	my $prefiksid = &finn_prefiksid($ip);
#	print "\n-$ip--".$prefiksid;
#	print "$iper{$ip} eq $prefiksid\n";
#	unless ($iper{$ip} eq $prefiksid ){#|| !$iper{$ip}) {
#	    print "$tabell - $felt_endres - $iper{$ip} - $prefiksid - $felt_fast - $ip\n";
#	    unless($prefiksid) {
#		$prefiksid="null";
#	    }
	    my $where = "$felt_fast=\'$ip\'";
	    &db_update($db,$tabell,$felt_endres,$iper{$ip},$prefiksid,$where);
#	 }
    }
}

