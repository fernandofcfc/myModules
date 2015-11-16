package Syslog::Filter::PgLog::Panic;

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
	
	$self->{_textRegex}			= "PANIC:";
	$self->{_textFieldsRegex}	= "PANIC: (.+)";
	$self->{_textFields}		= ["tx_message"]; 	 
	
	bless($self,$class);
	
	return $self;
}

1;