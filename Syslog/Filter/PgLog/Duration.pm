package Syslog::Filter::PgLog::Duration;

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
	
	$self->{_textRegex}			= "duration:";
	$self->{_textFieldsRegex}	= " ([0-9.]+) ms\$";
	$self->{_textFields}		= ["nu_statement_duration_ms"]; 	 
	
	bless($self,$class);
	
	return $self;
}

1;