package DbConn::Exception;

##
#
##

use Error;
use strict;

our @ISA = qw(Error);

use constant UNDEFINED_FAILURE	=>	"UNDEFINED FAILURE";

#
# Mapeamento de Exceções
# 
my %exceptionList	=	(
							# MAPA CODIGO => DESCRIÇÃO
							0	=> "DBMS NOT IMPLEMENTED",
							1	=> "COULD NOT CONNECT TO DATABASE INSTANCE",
							2	=> "INVALID STATEMENT",
							3	=> "ERROR IN EXECUTION",
							4	=> "COULD NOT FETCH ROW",
							5	=> "UNDEFINED PARAMETER PASSED TO FUNCTION",
							6	=> "INVALID PARAMETER PASSED TO FUNCTION",
							
							# Erros exclusivos do Postgres
							101	=> "PGLOADER FAILURE"				
						);

##
# public new
#
# @param $value	código da exceção
# @param $text 	mensagem da exceção
##
sub new
{
	my $self	= shift;
	
	my $value	= shift;
	my $message	= shift;
	my $text	= "";
	my @args 	= ();
	
	if(defined  $exceptionList{"$value"}) 
	{
		$text .=  $exceptionList{"$value"};
	}
	else
	{
		$text .= UNDEFINED_FAILURE;
	}
	
	$text	.=	" - $message"	if(defined $message);
	
	local $Error::Depth = $Error::Depth + 1;	# Muda a profundidade de informação do stacktrace	
	local $Error::Debug = 1;					# Habilita o stacktrace
	
	$self->SUPER::new(-text => $text, -value => $value, @args);
}

1;