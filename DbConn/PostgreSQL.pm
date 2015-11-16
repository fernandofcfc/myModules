package DbConn::PostgreSQL;

=for comment

=cut

use DbConn::Abstract;
use DbConn::PostgreSQL::Pgloader;
use strict;

our @ISA = qw(DbConn::Abstract);

use constant DBMS	=> "Pg";
use constant PASS	=> "dummy";


# public new
#
#
sub new
{
	my $class 	= $_[0];
	my $self	= $class->SUPER::new();
	
	$self->{_dbms}		= DBMS;
	$self->{_user}		= "postgres";
	
	$self->{_pgLoader}	= undef;
	
	bless($self,$class);
	
	return $self;
}

# public connect
#
#
sub connect
{
	my $self	= shift;
	my $hash	= shift;	
	
	my $user	= $self->{_user};
	$user		= $$hash{-user} if(defined $$hash{-user});
	
	my $pass	= PASS;
	$pass		= $$hash{-pass} if(defined $$hash{-pass});
	
	$self->{_host}	= $$hash{-host} if(defined $$hash{-host});

        my $port        = 5432;
        $port           = $$hash{-port} if (defined $$hash{-port});
	
	$self->{_dbName}	= $self->{_user};
	$self->{_dbName}	= $$hash{-dbname} if(defined $$hash{-dbname});	
	
	$self->SUPER::connect(	$self->{_dbms}.":dbname=".$self->{_dbName}.";host=".$self->{_host}.";port=".$port, $user, $pass);
	
	$self->{_pgLoader}	= DbConn::PostgreSQL::Pgloader->new(	$self->{_host},
									$self->{_dbName},
									$self->{_user},
									$pass,
									$port);
}

# public callFunction
#
#
sub callFunction
{
	my $self		= shift;
	my $function	= shift;
	my $parameters	= shift;
	
	my $paramString	= "";
	
	if((defined $parameters) && (scalar(@{$parameters})>0))
	{
		my @formattedParams	= ();
		
		foreach my $param (@{$parameters})
		{
			push @formattedParams, $self->_formatValue($param);
		}
		
		$paramString	= join(", ",@formattedParams);
	}
	
	my $sql	= "SELECT $function($paramString)";
	
	return $self->fetchOne($sql);
}

# public createDatabase
#
#
sub createDatabase
{
	my $self	= shift;
	my $dbname	= shift;
	my $params	= shift;	# TODO aceitar parametros para a criação de bases de dados
	
	my $sql		= "CREATE DATABASE $dbname";
	
	if((defined $params) && ($params =~ /HASH/))
	{
		my @paramsString	= ();
		
		foreach my $parameter (keys %{$params})
		{
			push @paramsString, "$parameter ".$$params{$parameter};
		}
		
		$sql	= "$sql ".join(" ", @paramsString);
	}
	
	$self->execute($sql);
}

# public dropDatabase
#
#
sub dropDatabase
{
	my $self	= shift;
	my $dbname	= shift;
	
	my $sql		= "DROP DATABASE $dbname";
	
	$self->execute($sql);
}

# public getPgLoader
#
# 
sub getPgLoader
{
	my $self	= shift;
	return $self->{_pgLoader};
}

1;
