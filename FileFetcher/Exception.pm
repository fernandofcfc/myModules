package FileFetcher::Exception;

use Error;
use strict;

our @ISA = qw(Error);

use constant UNDEFINED_FAILURE	=>	"UNDEFINED FAILURE";

#
# Mapeamento de Exceções
# 
my %exceptionList	=	(
							# MAPA CODIGO => DESCRIÇÃO
							0	=> "INVALID PARAMETER",
							1	=> "REMOTE CONNECTION NOT IMPLEMENTED",
							2	=> "FAILED TO DOWNLOAD FILE",
							3	=> "COULD NOT REMOVE LOCAL FILES",
							4	=> "UNDEFINED REMOTE CONNECTION",
							5	=> "UNDEFINED CONTROL FILE"
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