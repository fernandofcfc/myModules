package DbConn::PostgreSQL::Exception;

use DbConn::Exception;
use strict;

our @ISA = qw(DbConn::Exception);


# public new
#
# @param $value		Código da exceção
# @param $message	Mensagem de erro
sub new
{
	my $self	= 	shift;
	my $value	=	shift;
	my $message	=	shift;
	
	local $Error::Depth = $Error::Depth + 1;
	
	$self->SUPER::new($value,$message);
}

1;