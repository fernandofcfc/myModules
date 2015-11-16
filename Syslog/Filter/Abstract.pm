package Syslog::Filter::Abstract;

=for comment

=cut

use Util;
use strict;

# public new
#
#
sub new
{
	my $class 	= shift;
	my $self 	= {};
	
	$self->{_program}			= undef;
	$self->{_textRegex}			= undef;
	$self->{_textHeaderRegex}	= undef;
	$self->{_textFieldsRegex}	= undef;
	
	$self->{_header}	= {	"nm_host"		=> "host",
							"ts_register"	=> "timestamp",
							"nu_pid"		=> "pid",
							"tx_text"		=> "text"	};
							
	$self->{_textHeader}	= [];	 
	$self->{_textFields}	= []; 
	
	bless($self,$class);
	
	return $self;	
}

# public extract
#
#
sub extract
{
	my $self		= shift;
	my $registers	= shift;
	
	my @extracted	= ();
	
	foreach my $register (@{$registers})
	{
		next if ($$register{program} ne $self->{_program});
		next if (!($$register{text} =~ /$self->{_textRegex}/));
		
		my %hash	= ();
		my $text	= $$register{text};
		
		# extrai header do syslog
		foreach my $column (keys %{$self->{_header}})
		{
			if($self->{_header}->{$column} =~ /timestamp/)
			{
				$hash{$column}	= Util::timestampToString($$register{$self->{_header}->{$column}},1);
			}
			else
			{
				$hash{$column}	= $$register{$self->{_header}->{$column}};
			}
		}
		
		# extrai header do text
		if(scalar(@{$self->{_textHeader}}))
		{
			my @header	= $text	=~ /$self->{_textHeaderRegex}/;
			
			for( my $i = 0; $i < scalar(@{$self->{_textHeader}}); $i++)
			{
				$hash{$self->{_textHeader}->[$i]}	= $header[$i];
			}
		}
		
		# extrai dados do text
		if(scalar(@{$self->{_textFields}}))
		{
			my @fields	= $text	=~ /$self->{_textFieldsRegex}/;
			
			for( my $i = 0; $i < scalar(@{$self->{_textFields}}); $i++)
			{
				$hash{$self->{_textFields}->[$i]}	= $fields[$i];
			}
		}
		
		push @extracted, \%hash;
	}
	
	return \@extracted;
}

1;