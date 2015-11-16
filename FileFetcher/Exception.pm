package FileFetcher::Exception;

use Error;
use strict;

our @ISA = qw(Error);

use constant UNDEFINED_FAILURE	=>	"UNDEFINED FAILURE";

#
# Mapeamento de Exce��es
# 
my %exceptionList	=	(
							# MAPA CODIGO => DESCRI��O
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
# @param $value	c�digo da exce��o
# @param $text 	mensagem da exce��o
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
	
	local $Error::Depth = $Error::Depth + 1;	# Muda a profundidade de informa��o do stacktrace	
	local $Error::Debug = 1;					# Habilita o stacktrace
	
	$self->SUPER::new(-text => $text, -value => $value, @args);
}

1;