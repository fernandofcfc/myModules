package DbConn::Statement;

use strict;

##
# 
#
##

##
#
##
sub new
{
	my $class 	= shift;
	my $self 	= {};
	
	$self->{_statement}	= shift;
	
	bless($self,$class);
	
	return $self;
}

##
#
##
sub toString
{
	my $self	= shift;
	return $self->{_statement};
}

1;