# by Anarion
#  anarion@7a69ezine.org
package DNS::TinyDNS::dnsserver;

our @ISA=qw(DNS::TinyDNS);
our $VERSION="0.13";

=head1 NAME

DNS::TinyDNS::dnsserver - Perl extension for manipulating dnsserver from djbdns 

=head1 SYNOPSIS

	use DNS::TinyDNS;
	
	# First create the object
	my $dnsserver = DNS::TinyDNS->new(type => 'dnsserver',
			           	  dir  => '/service/tinydns');


=head1 DESCRIPTION

This module will allow you to manipulate djbdns dnsserver files.

=head1 FUNCTIONS

=over 4

=item get_env set_env

You can set/get the this vars:

    IP
    ROOT
    
For further information about every var, consult djbdns server documentation at
C<http://cr.yp.to/>

=item list_zones

This method returns an array of all the diferent zones configured

    my @zones=$dnsserver->list_zones;

=item get_zone

This method returns an array of hashes with all records of one zone.
The items of the hash deppends on the type of the record

    my @zone_e = $dnsserver->get_zone('catalunya.cat');

The hash have the following keys:

	type 		=> String showing the type of the record
		    ('DNS Server','DNS Delegate','HOST','ALIAS','MX)
	ttl 		=> ttl of the record
	ip  		=> ip of the host
	host 		=> host is only set with ns or mx records
	priority 	=> is only set with mx records

=item list

This method return an array of hashes with all records of one type.
Posible types are: mx, ns, host, alias or all
    
    my @mxs = $dnsserver->list(type => 'mx' ,
                               zone => '7a69ezine.org');

=item add

This method adds a mx record

    	      $dnsserver->add(zone => '7a69ezine.org',
			      type => 'mx',
                              ip   => '10.0.0.1',
                              host => 'rivendel',
                              pref => 10,
                              ttl  => 84500,
                              );


This method adds a ns record

              $dnsserver->add(zone => '7a69ezine.org',
			      type => 'ns',
                              ip   => '10.0.0.1',
                              host => 'rivendel',
                              ttl  => 84500,
                              );


This method adds a host record

              $dnsserver->add(zone => '7a69ezine.org',
			      type => 'host',
                              ip   => '10.0.0.1',
                              host => 'rivendel',
                              ttl  => 84500,
                                 );

This method adds a alias record

              $dnsserver->add(zone => '7a69ezine.org',
			      type => 'alias',
                              ip   => '10.0.0.1',
                              host => 'rivendel',
                              ttl  => 84500,
                              );

=item del

This method delete a mx record

    	      $dnsserver->del(zone => '7a69ezine.org',
			      type => 'mx',
                              ip   => '10.0.0.1',
                              host => 'rivendel',
                              pref => 10,
                              );


This method delete a ns record

              $dnsserver->del(zone => '7a69ezine.org',
			      type => 'ns',
                              ip   => '10.0.0.1',
                              host => 'rivendel',
                              );


This method delete a host record

              $dnsserver->del(zone => '7a69ezine.org',
			      type => 'host',
                              host => 'rivendel',
                              ip   => '10.0.0.1',
                                 );

This method delete a alias record

              $dnsserver->del(zone => '7a69ezine.org',
			      type => 'alias',
                              host => 'rivendel',
                              ip   => '10.0.0.1',
                              );


=cut

use Carp;
use Fcntl qw(:DEFAULT :flock);
use Cwd;

my %types = ('ns'     => '[.&]',
	     'host'   => '=',
	     'alias'  => '+',
	     'mx'     => '@',
	     'all'    => '[\.&=+\@]');

my %parse = ( 'ns'    => \&_parse_ns,
              'host'  => \&_parse_host,
              'alias' => \&_parse_alias,
              'mx'    => \&_parse_mx,
              'all'   => \&_parse_all );


sub new
{
	my ($clase,$dir)=@_;
	my $self = { dir 	=> $dir,
		     t_env	=> { 	IP		=> '',
					ROOT		=> ''
				   },
		     svc	=> '/usr/local/bin/svc'				   
		   };
	return bless $self,$clase;
}

sub start
{
    my $self=shift;
    my $c_dir=getcwd;
    chdir($self->{dir})
        or carp "Error cant chdir to $self->{dir}";
    system "make"
        and carp "Error cant make database";
    chdir($c_dir);
    $self->SUPER::start();
}

sub restart
{
    my $self=shift;
    my $c_dir=getcwd;
    chdir($self->{dir})
        or carp "Error cant chdir to $self->{dir}";
    system "make"
        and carp "Error cant make database";
    chdir($c_dir);
    $self->SUPER::restart();
}

sub list
{
    my ($self,%options)=@_;
    my $file=$self->{dir} . "/root/data";
    my (@zone);
    local *FILE;    
    
    unless($self->{dir} and -f $file)
    {
        carp "ERROR: dnsserver directory not set";
        return 0;
    }

    unless($options{type} and exists $types{$options{type}})
    {
        carp "ERROR: this type doesnt exists.";
        return 0;
    }
    
    open(FILE,$file) 
        or carp "ERROR: Cant read from $file";
    flock(FILE,LOCK_EX)
        or carp "Cant lock $file";
    seek(FILE,0,0)
        or carp "ERROR: Cant seek $file";
    while(my $entrada=<FILE>)
    {
        chomp($entrada);
        if($entrada=~/^$types{$options{type}}/)
        {
            	next if $options{zone} and $entrada !~ /^.([\w\.\-]*\.)*\Q$options{zone}\E:/;
		push(@zone,$parse{$options{type}}->($entrada));
        }
    }
    close FILE
	or carp "Error: Cant Close File";
    return @zone;
}

sub list_zones
{
	my $self = shift;
	my $file=$self->{dir} . "/root/data";
	my %zones;
	local *FILE;

	unless($self->{dir} and -f $file)
	{
	        carp "ERROR: dnsserver directory not set";
	        return 0;
	}

	open(FILE,$file) 
		or carp "ERROR: Cant read from $file";
	flock(FILE,LOCK_EX)
	        or carp "Cant lock $file";
	seek(FILE,0,0)
	        or carp "ERROR: Cant seek $file";
	while(my $entrada=<FILE>)
	{
		$zones{$1}++ if $entrada=~/^.[\w\.\-]*\.([\w\-]+\.\w{2,4}):/;
	}
	close FILE
		or carp "Error: Cant Close File";
	return keys %zones;
}

sub get_zone
{
	my ($self,$zone) = @_;
	my $file=$self->{dir} . "/root/data";
	my @zone;
	local *FILE;

	unless($self->{dir} and -f $file)
	{
	        carp "ERROR: dnsserver directory not set";
	        return 0;
	}

	open(FILE,$file) 
		or carp "ERROR: Cant read from $file";
	flock(FILE,LOCK_EX)
	        or carp "Cant lock $file";
	seek(FILE,0,0)
	        or carp "ERROR: Cant seek $file";
	while(my $entrada=<FILE>)
	{
		if ($entrada=~/^$types{all}([\w\.\-]*\.)*\Q$zone\E:/)
		{
			push(@zone,_parse_all->($entrada));
		}	
	}
	close FILE
		or carp "Error: Cant Close File";
	return @zone;	
}

sub add
{
	my ($self,%options)=@_;
	my $file=$self->{dir} . "/root/data";
	my $string;
	local *FILE;

	unless($self->{dir} and -f $file)
	{
	        carp "ERROR: dnsserver directory not set";
	        return 0;
	}

	unless($options{type} and exists $types{$options{type}})
	{
		carp "ERROR: this type doesnt exists.";
	        return 0;
	}

	open(FILE,">>$file") 
		or carp "ERROR: Cant read from $file";
	flock(FILE,LOCK_EX)
	        or carp "Cant lock $file";
        seek(FILE,0,2)
	        or carp "ERROR: Cant seek $file";
	$options{ttl}||="86400"; # 1 day
	for($options{type})
	{
		$string =
		/ns/ 	&& do { "&$options{zone}:$options{ip}:$options{host}:$options{ttl}" 		}	||
		/mx/ 	&& do { "\@$options{zone}:$options{ip}:$options{host}:$options{ttl}:$options{pref}"} 	||
		/host/ 	&& do { "=$options{host}.$options{zone}:$options{ip}:$options{ttl}" 		}	||
		/alias/ && do { "+$options{host}.$options{zone}:$options{ip}:$options{ttl}" 		}	or
		warn "NOT FOUND ($_)";
	}
	syswrite(FILE,"$string\n");
	close(FILE)
		or carp "Error: Cant close file";
}

sub del
{
	my ($self,%options)=@_;
	my $file=$self->{dir} . "/root/data";
	my $string;
	local (*FILE,*FILENEW);

	unless($self->{dir} and -f $file)
	{
	        carp "ERROR: dnscache directory not set";
	        return 0;
	}

	unless($options{type} and exists $types{$options{type}} and $options{zone})
	{
		carp "ERROR: not enougth arguments.";
	        return 0;
	}

	open(FILENEW,">$file.new") 
		or carp "ERROR: Cant write to $file.new";
	flock(FILENEW,LOCK_EX)
	        or carp "Cant lock $file.new";

	open(FILE,"<$file") 
		or carp "ERROR: Cant read from $file.new";
	flock(FILE,LOCK_EX)
	        or carp "Cant lock $file";

        seek(FILE,0,0)
	        or carp "ERROR: Cant seek $file";
        seek(FILENEW,0,0)
	        or carp "ERROR: Cant seek $file.new";

	ENTRADA:
	while(my $entrada=<FILE>)
	{
		for($options{type})
		{
			/host|alias/ && $entrada=~/^[=+]\Q$options{host}\E\.\Q$options{zone}\E:\Q$options{ip}\E/ 				&&
					do { next ENTRADA } ||
			/mx/	     && $entrada=~/^\@\Q$options{zone}\E:\Q$options{ip}\E:\Q$options{host}\E:[^:]*:\Q$options{pref}\E\s*$/ 	&&
					do { next ENTRADA } ||
			/ns/	     && $entrada=~/^[.&]\Q$options{zone}\E:\Q$options{ip}\E:\Q$options{host}\E:/				&&
					do { next ENTRADA } 
		}
		syswrite(FILENEW,$entrada);
	}	

	close(FILENEW)
	    or carp "ERROR: Cant close $file.new";
	close(FILE)
            or carp "ERROR: Cant close $file";
        unlink($file)
            or carp "ERROR: Cant unlink $file";
        rename("$file.new",$file)
            or carp "ERROR: Cant rename $file.new to $file";
}

### PRIVATE SUBS
sub _parse_ns
{
    my @data=split/:/,substr($_[0],1);
    return { zone => $data[0],
             ip   => $data[1],
             host => $data[2],
             ttl  => $data[3]  };
}

sub _parse_mx
{
    my @data=split/:/,substr($_[0],1);
    return { zone => $data[0],
             ip   => $data[1],
             host => $data[2],
             ttl  => $data[4],
             pref => $data[3]  };
}

sub _parse_host
{
    my @data=split/:/,substr($_[0],1);
    return { zone => $data[0],
             ip   => $data[1],
             ttl  => $data[2]  };
}

sub _parse_alias
{
    my @data=split/:/,substr($_[0],1);
    return { zone => $data[0],
             ip   => $data[1],
             ttl  => $data[2]  };
}

sub _parse_all
{
    my $tipus=substr($_[0],0,1);
    my %types = ( '.'    => \&_parse_ns,
                  '&'    => \&_parse_ns,
                  '='    => \&_parse_host,
                  '+'    => \&_parse_alias,
                  '@'    => \&_parse_mx );
    return $types{$tipus}->($_[0]);
}

1;
