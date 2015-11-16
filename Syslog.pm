package Syslog;

=for comment

	*******************************************************************
	module:		Syslog
	package:	Syslog
	author:		Vinicius Porto Lima
	date:		
	version:	
	
	description:
	
	*******************************************************************
	change log
	author:				date:			description:
	
	*******************************************************************
	
=cut

use Parse::Syslog;
use DbConn;
use DbConn::Exception;
use Logger;
use Syslog::Exception;
use Syslog::Filter;
use Error qw(:try);
use strict;

use constant DBMS				=> "PGSQL";	#
use constant MAX_ROUND_REGS		=> 100000;	#
use constant TOLERANCE_COUNT	=> 1000;	#

# public new
#
#
sub new
{
	my $class 	= shift;
	my $self 	= {};
	
	$self->{_path}		= shift;	
	throw Syslog::Exception(1, $self->{_path}) if(! -f $self->{_path});
	
	$self->{_registros}	= {};	# Hash{filter_name}	= Array[Hash{column_name} => $value];
	 
	bless($self,$class);
	
	return $self;	
}

# public parse
#
#
sub parse
{
	my $self	= shift;
	my $filters	= shift;
	
	my @registros		= ();
	
	# recupera registros em hash do arquivo
	my $parseSyslog		= Parse::Syslog->new($self->{_path});
	
	while (my $register	= $parseSyslog->next())
	{
		push @registros, $register;
	}
	
	# aplica filtros
	foreach my $filterName (@{$filters})
	{
		$self->{_registros}->{$filterName}	= Syslog::Filter::select($filterName)->extract(\@registros);
	}
}

# public parseNLoadWithPgLoader
#
#
sub parseNLoadWithPgLoader
{
	my $self	= shift;
	my $filters	= shift;
	my $params	= shift;
	
	my @registros		= ();
	my $dbConn;
	
	# verificando conexao com o banco de dados
	if(not exists $$params{-dbConn})
	{
		$dbConn	= DbConn::sessionInstance();
	} 
	else
	{
		$dbConn	= $$params{-dbConn};
	}
	
	$dbConn->getPgLoader()->setWorkingDir($$params{-workingDir}) if(exists $$params{-workingDir});
	$dbConn->getPgLoader()->setLogsDir($$params{-logsDir}) if(exists $$params{-logsDir});
	
	# recupera registros em hash do arquivo
	my $parseSyslog		= Parse::Syslog->new($self->{_path});
	
	while (my $register	= $parseSyslog->next())
	{
		push @registros, $register;
	}
	
	# aplica filtros
	foreach my $filterName (@{$filters})
	{
		my @filteredRegs	= @{Syslog::Filter::select($filterName)->extract(\@registros)};
		try
		{
			Logger::addLog("Carga $filterName");
			
			if(scalar(@filteredRegs))
			{
				my $loadingName	= $dbConn->getPgLoader()->load($filterName, \@filteredRegs);
				Logger::addLog("\t $loadingName carregado");
			}
			else
			{
				Logger::addLog("\t 0 registros a carregar");
			}
		}
		catch DbConn::Exception with
		{
			my $ex	= shift;
			Logger::addException($ex->text(), $ex->value(), $ex->stacktrace());
		};
		@filteredRegs = ();
		undef @filteredRegs;
	}
}

# public load
#
# deprecated
sub load
{
	my $self		= shift;
	my $connHash	= shift;
	
	if(scalar(keys(%{$self->{_registros}})))
	{
		my $dbConn	= DbConn::getDbmsConn(DBMS);
		
		try
		{
			$dbConn->connect($connHash);
			
			foreach my $filterName (keys %{$self->{_registros}})
			{
				$dbConn->beginTransaction();
								
				try
				{		
					$dbConn->insertRows($filterName,$self->{_registros}->{$filterName});
					$dbConn->commit();
				}
				catch DbConn::Exception with
				{
					my $ex	= shift;
				
					$dbConn->rollback();
					Logger::addException($ex->text(), $ex->value(), $ex->stacktrace());
				};
			}
			
			$dbConn->disconnect();
		}
		catch DbConn::Exception with
		{
			my $ex	= shift;
				
			Logger::addException($ex->text(), $ex->value(), $ex->stacktrace());
		};
	}	
}


# public parseNLoad
#
# deprecated
sub parseNLoad
{
	my $self		= shift;
	my $filters		= shift;
	my $connHash	= shift;
	
	# recupera registros em hash do arquivo
	my $parseSyslog		= Parse::Syslog->new($self->{_path});
	
	my @registros		= ();
	my $lastPid			= 0;
	my $rounds			= 0;
	my $toleranceCount	= TOLERANCE_COUNT;
	
	while (my $register	= $parseSyslog->next())
	{
		push @registros, $register;
		
		my $pid		= $$register{pid};
		
		if($rounds++ > MAX_ROUND_REGS)
		{
			if(($pid != $lastPid) || ($toleranceCount-- <= 0))
			{
				# aplica filtros
				foreach my $filterName (@{$filters})
				{
					$self->{_registros}->{$filterName}	= Syslog::Filter::select($filterName)->extract(\@registros);
				}
				
				# carrega na base de dados
				$self->load($connHash);
				@registros				= ();
				$self->{_registros}		= {};
				
				$rounds			= 0;
				$toleranceCount	= TOLERANCE_COUNT;
			}
		}
		
		$lastPid	= $pid;
	}
	
	if(scalar(@registros))
	{
		# aplica filtros
		foreach my $filterName (@{$filters})
		{
			$self->{_registros}->{$filterName}	= Syslog::Filter::select($filterName)->extract(\@registros);
		}
				
		# carrega na base de dados
		$self->load($connHash);
		@registros				= ();
		$self->{_registros}		= {};
	}
}

# public printContent
#
#
sub printContent
{
	my $self	= shift;
	
	foreach my $filterName (keys %{$self->{_registros}})
	{
		print "FILTRO $filterName:\n";
		my $fst	= 0;
		
		foreach my $reg (@{$self->{_registros}->{$filterName}})
		{
			if(!$fst++)
			{
				print join(";",sort(keys(%{$reg})))."\n";
			}
			
			my @cols	= ();
			
			foreach my $colName (sort(keys(%{$reg})))
			{
				push @cols, $$reg{$colName};
			}
			
			print join(";", @cols)."\n"; 
		}
		
		print "\n";
	}
}

1;
