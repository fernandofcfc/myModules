package Syslog::Filter::PgLog::ConnectionAuthorized;

use Syslog::Filter::PgLog::Abstract;
use strict;

our @ISA = qw(Syslog::Filter::PgLog::Abstract);

##
# public new
##
sub new
{
	my $class 	= $_[0];
	my $self	= $class->SUPER::new();
	
	$self->{_textRegex}			= "connection authorized";
	
	bless($self,$class);
	
	return $self;
}

1;