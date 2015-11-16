package Syslog::Filter::PgLog::Fatal;

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
	
	$self->{_textRegex}			= "FATAL:";
	$self->{_textFieldsRegex}	= "FATAL: (.+)";
	$self->{_textFields}		= ["tx_message"]; 	 
	
	bless($self,$class);
	
	return $self;
}

1;