# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'
#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use warnings;
use lib ".";
use Test::Simple tests => 24;
use DNS::TinyDNS;

my $dnscache = DNS::TinyDNS->new;
my %config;

ok( ! $dnscache );
$dnscache = DNS::TinyDNS->new( type	=> 'some_undefined_type');

# Tests 4 dnscache
ok( ! $dnscache );
$dnscache = DNS::TinyDNS->new( type	=> 'dnscache');
ok( $dnscache );
$dnscache = DNS::TinyDNS->new( type	=> 'dnscache',
			       dir	=> '/some_dir_that/doesnt_exist');
ok( $dnscache );
$dnscache = DNS::TinyDNS->new( type	=> 'dnscache',
			       dir	=> '/service/dnscachex');
ok( $dnscache );
print STDERR "Enter the directory root of dnscache ['/service/dnscachex']:\n";
chomp(my $dir = <STDIN>);
$dir||="/service/dnscachex";
ok( $dnscache->dir($dir) );
ok( $dnscache->dir );
ok( $config{ip}=$dnscache->get_env('ip') );
ok( $config{ipsend}=$dnscache->get_env('ipsend') );
ok( $config{cachesize}=$dnscache->get_env('cachesize') );
ok( $config{datalimit}=$dnscache->get_env('datalimit') );
ok( $config{root}=$dnscache->get_env('root') );
{
	my @a = $dnscache->get_env( qw{cachesize ip datalimit} );
	ok( 3 == @a );
}
ok( $dnscache->set_env( ip 		=> $config{ip} 		) );
ok( $dnscache->set_env( root 		=> $config{root}  	) );
ok( $dnscache->set_env( cachesize 	=> $config{cachesize}  	) );
ok( $dnscache->set_env( datalimit 	=> $config{datalimit}  	) );
ok( $dnscache->set_env( ipsend 		=> $config{ipsend} 	) );
ok( $dnscache->set_env( ip 		=> $config{ip}, 
			root 		=> $config{root},  	
			cachesize 	=> $config{cachesize}  	) );
ok( $dnscache->add_ip( '10.0.0.13' ) );
ok( $dnscache->del_ip( '10.0.0.13' ) );
ok( $dnscache->list_ips );
ok( $dnscache->list_servers );
ok( $dnscache->add_server( '10.0.0.13' ) );
ok( $dnscache->del_server( '10.0.0.13' ) );
# End of dnscache tests

# Test for dnsserver
my $dnsserver = DNS::TinyDNS->new(type => 'dnsserver');
%config = ();

ok( $dnsserver );
print STDERR "Enter the directory root of dnsserver ['/service/tinydns']:\n";
chomp(my $dir = <STDIN>);
$dir||="/service/tinydns";
ok( $dnsserver->dir($dir) );
ok( $dnsserver->dir );
ok( $config{ip}=$dnsserver->get_env('ip') );
ok( $config{root}=$dnsserver->get_env('root') );
{
	my @a = $dnsserver->get_env( qw{ip root} );
	ok( 2 == @a );
}
ok( $dnsserver->set_env( ip 		=> $config{ip} 		) );
ok( $dnsserver->set_env( root 		=> $config{root}  	) );
ok( $dnsserver->list_zones );
ok( $dnsserver->list( type		=> 'mx',
		      zone		=> 'localhost'		) );
ok( $dnsserver->get_zone( 'localhost' ) );
ok( $dnsserver->add(	zone => '7a69ezine.org',
		   	type => 'host',
                        ip   => '10.0.0.1',
                        host => 'rivendel',
                        ttl  => 84500,		) );
ok( $dnsserver->del(	zone => '7a69ezine.org',
		   	type => 'host',
                        ip   => '10.0.0.1',
                        host => 'rivendel',
                        ttl  => 84500,		) );
