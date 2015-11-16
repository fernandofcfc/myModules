package Mail::Text;

=for comment

=cut

use Mail::Abstract;
use strict;

our @ISA = qw(Mail::Abstract);
							
##
# public new
##
sub new
{
	my $class 	= $_[0];
	my $self	= $class->SUPER::new();
		
	bless($self,$class);	# associa o objeto self à classe class
	
	return $self;
}

1;