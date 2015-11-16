package Mail::HTML;

=for comment

=cut

use Mail::Abstract;
use strict;

our @ISA = qw(Mail::Abstract);

use constant DEFAULT_CHARSET	=> "ISO-8859-1";

##
# public new
##
sub new
{
	my $class 	= $_[0];
	my $self	= $class->SUPER::new();
	
	$self->{_message}->attr("content-type"			=> "text/html");
	$self->{_message}->attr("content-type.charset"	=> DEFAULT_CHARSET);
		
	bless($self,$class);	# associa o objeto self à classe class
	
	return $self;
}

1;