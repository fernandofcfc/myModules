package Syslog::Filter::PgLog::Statement;

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
	
	$self->{_textRegex}			= "statement:";
	$self->{_textFieldsRegex}	= "statement: (.+)";
	$self->{_textFields}		= ["tx_statement"]; 	 
	
	bless($self,$class);
	
	return $self;
}

1;