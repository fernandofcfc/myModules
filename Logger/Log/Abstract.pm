package Logger::Log::Abstract;

use Util;
use strict;

##
#
##

##
#
##
sub new
{
	my $class 	= shift;
	my $self 	= {};
	
	$self->{_text}		= undef; 
	$self->{_severity}	= undef;
	$self->{_timestamp}	= time();
	$self->{_token}		= lc Util::token();  
	
	bless($self,$class);
	
	return $self;	
}

sub setText
{
	my $self	= shift;
	my $text	= shift;
	$self->{_text}	= $text;
}

sub getText
{
	my $self	= shift;
	return $self->{_text};
}

sub setSeverity
{
	my $self		= shift;
	my $severity	= shift;
	$self->{_severity}	= $severity;
}

sub getSeverity
{
	my $self	= shift;
	return $self->{_severity};
}

sub getTimestamp
{
	my $self	= shift;
	return $self->{_timestamp};
}

sub getTimestampString
{
	my $self	= shift;
	return Util::timestampToString($self->{_timestamp});
}

sub getToken
{
	my $self	= shift;
	return $self->{_token};
}

1;