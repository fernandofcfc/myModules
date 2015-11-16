package Syslog::Filter::Exception;

use Syslog::Exception;
use strict;

our @ISA = qw(Syslog::Exception);

##
# public new
#
# @param $value		C�digo da exce��o
# @param $message	Mensagem de erro
##
sub new
{
	my $self	= 	shift;
	my $value	=	shift;
	my $message	=	shift;
	
	local $Error::Depth = $Error::Depth + 1;
	
	$self->SUPER::new($value,$message);
}

1;