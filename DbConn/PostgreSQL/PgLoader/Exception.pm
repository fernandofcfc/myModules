package DbConn::PostgreSQL::PgLoader::Exception;

use DbConn::PostgreSQL::Exception;
use strict;

our @ISA = qw(DbConn::PostgreSQL::Exception);


# public new
#
# @param $value		C�digo da exce��o
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