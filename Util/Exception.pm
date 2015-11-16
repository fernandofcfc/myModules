package Util::Exception;

use Error;
use strict;

our @ISA = qw(Error);

use constant UNDEFINED_FAILURE	=>	"UNDEFINED FAILURE";

#
# Mapeamento de Exceções
# 
my %exceptionList	=	(
							# MAPA CODIGO => DESCRIÇÃO
							0	=> "INVALID PARAMETERS",
							1	=> "COULD NOT MAKE DIR",
							2	=> "COULD NOT REMOVE DIR",
							3	=> "COULD NOT COPY FILE",
							4	=> "COULD NOT GZIP FILE",
							5	=> "COULD NOT REMOVE OLD FILES",
							6	=> "COULD NOT OPEN/READ/WRITE FILE",
							7	=> "COULD NOT OPEN/READ DIR",
							8	=> "COULD NOT DECOMPRESS GZIP FILE",
							9	=> "COULD NOT SPLIT FILE",
							
							# INI FILE ERRORS
							100	=> "INVALID INI FILE",
							101	=> "SECTION DOES NOT EXIST IN THE INI FILE",
							102	=> "INVALID INI PARAM",
							103 => "INCOMPLETE INI SECTION"
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
