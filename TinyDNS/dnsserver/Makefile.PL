use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'DNS::TinyDNS::dnsserver',
    'VERSION_FROM'	=> 'dnsserver.pm', # finds $VERSION
    'PREREQ_PM'		=> { }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'dnsserver.pm', # retrieve abstract from module
       AUTHOR     => 'Anarion <anarion@7a69ezine.org>') : ()),
);
