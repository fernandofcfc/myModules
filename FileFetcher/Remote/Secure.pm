package FileFetcher::Remote::Secure;

=for comment

	*******************************************************************
	module:		FileFetcher
	package:	FileFetcher::Remote::Secure
	author:		Vinicius Porto Lima
	date:	
	version:
	
	description:
	
	*******************************************************************
	change log
	author:				date:			description:
	
	*******************************************************************
	
=cut

use FileFetcher::Remote::Abstract;
use strict;

our @ISA = qw(FileFetcher::Remote::Abstract);

# public new
#
#
sub new
{
	my $class 	= $_[0];
	my $self	= $class->SUPER::new($_[1],$_[2]);
	
	$self->{_shellStr}		= "ssh -l :user :ip \":cmd\":ex_cmd";			# template de conexão por ssh
	$self->{_transferStr}	= "scp :user\@:ip::remote_path :local_path";	# template de transferência de arquivos por scp
		
	bless($self,$class);	# associa o objeto self à classe class
	
	return $self;
}

1;