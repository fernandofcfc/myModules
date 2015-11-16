package FileFetcher::Remote::Abstract;

=for comment

	*******************************************************************
	module:		FileFetcher
	package:	FileFetcher::Remote::Abstract
	author:		Vinicius Porto Lima
	date:	
	version:
	
	description:
	
	*******************************************************************
	change log
	author:				date:			description:
	
	*******************************************************************
	
=cut

use strict;

# public new
#
#
sub new
{
	my $class 	= shift;
	my $self 	= {};
	
	$self->{_ip}	= shift;
	$self->{_user}	= shift;
	
	$self->{_shellStr}		= undef;	# string que armazena o codigo de abertura de conexão (ssh)
	$self->{_transferStr}	= undef;	# string que armazena o codigo de transferência de arquivo (scp)
	
	bless($self,$class);	# associa o objeto self à classe class
	
	return $self;
}

# public cmd
#
#
sub cmd
{
	my $self	= shift;
	my $cmd		= shift;
	my $exCmd	= shift;
	
	$exCmd		= ""  if(not defined $exCmd);
	
	my $string	= $self->{_shellStr};
	$string	=~ s/:user/$self->{_user}/;
	$string =~ s/:ip/$self->{_ip}/;
	$string	=~ s/:cmd/$cmd/;
	$string	=~ s/:ex_cmd/$exCmd/;
	
	my $output	= `$string`;
	
	# TODO tratar falhas de output
	
	return $output;
}

# public getFile
#
#
sub getFile
{
	my $self		= shift;
	my $remoteFile	= shift;
	my $localFile	= shift;
	
	my $string	= $self->{_transferStr};
	$string	=~ s/:user/$self->{_user}/;
	$string =~ s/:ip/$self->{_ip}/;
	$string	=~ s/:remote_path/$remoteFile/;
	$string	=~ s/:local_path/$localFile/;
	
	my $output	= `$string`;
	
	# TODO tratar falhas de output
}

1;