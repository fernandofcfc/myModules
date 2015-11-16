package DbConn::SQLServer;

use DbConn::Abstract;
use strict;

our @ISA = qw(DbConn::Abstract);

use constant DBMS	=> "Sybase";

##
# public new
##
sub new
{
	my $class 	= $_[0];
	my $self	= $class->SUPER::new();
	
	$self->{_dbms}	= DBMS;
	
	bless($self,$class);
	
	return $self;
}

##
# 
##
sub connect
{
	my $self	= shift;
	my $hash	= shift;	
	
	$self->{_host}	= $$hash{-host};
	$self->{_dbName}= $$hash{-dbname};
	
	$self->SUPER::connect(	$self->{_dbms}.":server=".$self->{_host}.";database=".$self->{_dbName},
							$$hash{-user}, 
							$$hash{-pass});
}

##
#
##
sub callFunction
{
	my $self		= shift;
#	my $function	= shift;
#	my $parameters	= shift;
#	
#	my $paramString	= "";
#	
#	if((defined $parameters) && (scalar(@{$parameters})>0))
#	{
#		my @formattedParams	= ();
#		
#		foreach my $param (@{$parameters})
#		{
#			push @formattedParams, $self->_formatValue($param);
#		}
#		
#		$paramString	= join(", ",@formattedParams);
#	}
#	
#	my $sql	= "SELECT $function($paramString)";
#	
#	return $self->fetchOne($sql);
}

##
# public createDatabase
##
sub createDatabase
{
	my $self	= shift;
	my $dbname	= shift;
#	my $params	= shift;	# TODO aceitar parametros para a criação de bases de dados
	
	my $sql		= "CREATE DATABASE $dbname";
	
#	if((defined $params) && ($params =~ /HASH/))
#	{
#		my @paramsString	= ();
#		
#		foreach my $parameter (keys %{$params})
#		{
#			push @paramsString, "$parameter ".$$params{$parameter};
#		}
#		
#		$sql	= "$sql ".join(" ", @paramsString);
#	}
	
	$self->execute($sql);
}

##
# public dropDatabase
##
sub dropDatabase
{
	my $self	= shift;
	my $dbname	= shift;
	
	my $sql		= "DROP DATABASE $dbname";
	
	$self->execute($sql);
}

1;