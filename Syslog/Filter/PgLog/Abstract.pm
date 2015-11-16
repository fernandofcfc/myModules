package Syslog::Filter::PgLog::Abstract;

=for comment



=cut

use Syslog::Filter::Abstract;
use Util;
use strict;

our @ISA = qw(Syslog::Filter::Abstract);

use constant SEQ_FIELD	=> "idseq";

##
# public new
##
sub new
{
	my $class 	= $_[0];
	my $self	= $class->SUPER::new();
	
	$self->{_program}			= "postgres";
	$self->{_textHeaderRegex}	= SEQ_FIELD."=(\\d+),tstamp=(\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}).+user=(.+),dbname=(.+),host=(.+),[A-Z]+:";
	$self->{_textHeader}		= ["id_seq","ts_pglog","nm_user","nm_dbname","nm_pghost"];	 
	
	bless($self,$class);
	
	return $self;
}

##
#
##
sub extract
{
	my $self			= shift;
	my $registers		= shift;
	
	my %auxTexts		= ();	# como nem todos os registros estão em ordem, é necessário ordená-los com essa variável utilizando o seq
	my %auxRegisters	= ();
	my @newRegisters	= ();
	
	# realiza ajuste de concatenação de textos no postgresql
	foreach my $register (@{$registers})
	{
		my $program		= $$register{program};
		my $host		= $$register{host};
		my $timestamp	= $$register{timestamp};
		my $pid			= $$register{pid};
		my $text		= $$register{text};
		
		next if($program ne $self->{_program});
		
		my ($id, $seq)	= $text	=~ /\[(\d+)\-(\d+)\]/;
		$text	=~ s/\[\d+\-\d+\]//;
		$text	= Util::trim($text);
		
		my $key	= "$timestamp|$pid|$id";
		
		if(not exists $auxRegisters{$key})
		{
			$auxRegisters{$key}	= {	program		=> $program,
									host		=> $host,
									timestamp	=> $timestamp,
									pid			=> $pid};
		}
		
		$auxTexts{$key}{ID}			= $id;
		$auxTexts{$key}{TEXT}{$seq}	= $text;
	}
	
	foreach my $key (sort keys %auxRegisters)
	{
		my $completeText	= "";
		my $fgFirst			= 0;	 
		
		foreach my $seq (sort keys %{$auxTexts{$key}{TEXT}})
		{
			my $text	= $auxTexts{$key}{TEXT}{$seq};
			
			if($fgFirst++)
			{
				$text			=~ s/tstamp=\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.+user=.+,dbname=.+,host=.+,//g;
				$completeText	.= " $text";
			}
			else
			{
				$completeText	= SEQ_FIELD."=".$auxTexts{$key}{ID}.",$text";
			} 
		}
		
		$auxRegisters{$key}{text}	= $completeText;
		push @newRegisters, $auxRegisters{$key};
	}
	
	$self->SUPER::extract(\@newRegisters);
}

1;