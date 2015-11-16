package Mail::Abstract;

=for comment

=cut

# TODO criar validação de endereço de email

use MIME::Lite;
use strict;

use constant TIMEOUT		=> 60;
use constant DEFAULT_TYPE	=> "text/plain";

##
# public new
##
sub new
{
	my $class 	= shift;
	my $self 	= {};
	
	my $type	= shift;
	$type		= DEFAULT_TYPE if(not defined $type);
	
	$self->{_subject}	= undef;
	$self->{_data}		= undef;
	$self->{_from}		= undef;
	$self->{_type}		= $type;
	
	$self->{_to}		= [];
	$self->{_cc}		= [];
	
	$self->{_attach}	= undef;

	bless($self,$class);	# associa o objeto self à classe class
	return $self;
}

##
# public send
##
sub send
{
	my $self	= shift;
	my $server	= shift;
	
	my $message	= MIME::Lite->new(	Subject	=> $self->{_subject},
						Data	=> $self->{_data},
						From	=> $self->{_from},
						To	=> join(",",@{$self->{_to}})
						
					);
									
	$message->add(Cc	=> join(",",@{$self->{_cc}})) if(scalar(@{$self->{_cc}}));
	
	MIME::Lite->send('smtp', $server, Timeout=>TIMEOUT);
	$message->send() or throw Mail::Exception(1);
}

##
# public sendAttach
##
sub sendAttach
{
	my $self	= shift;
	my $server	= shift;
	
	my $message	= MIME::Lite->new(	Subject	=> $self->{_subject},
						From	=> $self->{_from},
						To	=> join(",",@{$self->{_to}}),
						Path	=> $self->{_attach}
						
					);
									
	$message->add(Cc	=> join(",",@{$self->{_cc}})) if(scalar(@{$self->{_cc}}));
	
	MIME::Lite->send('smtp', $server, Timeout=>TIMEOUT);
	$message->send() or throw Mail::Exception(1);
}

##
# public setSubject
##
sub setSubject
{
	my $self	= shift;
	my $subject	= shift;
	
	$self->{_subject}	= $subject;
}


##
# public setAttach
##
sub setAttach
{
	my $self	= shift;
	my $attach	= shift;
	
	$self->{_attach}	= $attach;
}

##
# public setData
##
sub setData
{
	my $self	= shift;
	my $data	= shift;
	
	$self->{_data}	= $data;
}

##
# public setFrom
##
sub setFrom
{
	my $self	= shift;
	my $from	= shift;
	
	$self->{_from}	= $from;
}

##
# public addTo
##
sub addTo
{
	my $self	= shift;
	my $to		= shift;
	
	push @{$self->{_to}}, $to;
}

##
# public addCc
##
sub addCc
{
	my $self	= shift;
	my $cc		= shift;
	
	push @{$self->{_cc}}, $cc;
}



1;