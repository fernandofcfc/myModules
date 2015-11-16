package Logger::Log::Excpt;

use Logger::Log::Abstract;
use Logger::Log::Severity;
use strict;

##
#
#
#
##

our @ISA = qw(Logger::Log::Abstract);

##
#
##
sub new
{
	my $class 	= $_[0];
	my $self	= $class->SUPER::new();

	$self->{_severity}		= Logger::Log::Severity::EXCP_LVL;

	$self->{_text}			= $_[1];
	$self->{_value}			= $_[2];
	$self->{_stacktrace}	= $_[3];

	bless($self,$class);
	
	return $self;
}

sub getValue
{
	my $self	= shift;
	return $self->{_value};
}

sub getStacktrace
{
	my $self	= shift;
	return $self->{_stacktrace};
}

1;