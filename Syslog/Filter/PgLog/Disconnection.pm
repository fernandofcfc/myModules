package Syslog::Filter::PgLog::Disconnection;

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
	
	$self->{_textRegex}			= "disconnection:";
	$self->{_textFieldsRegex}	= "session time: (\\d+:\\d+:\\d+.\\d+) ";
	$self->{_textFields}		= ["tm_session_duration"]; 	 
	
	bless($self,$class);
	
	return $self;
}

1;