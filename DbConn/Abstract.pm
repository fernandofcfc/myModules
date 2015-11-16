package DbConn::Abstract;

=for comment
 
	*******************************************************************
	module:		DbConn
	package:	DbConn::Abstract
	author:		Vinicius Porto Lima
	date:
	version:	0.8		
	
	description:
	
	*******************************************************************
	change log
	author:				date:		description:
	Vinicius Porto		01/07/2013	adição do método DESTROY
	Vinicius Porto		03/07/2013	alteração do método fetchAll para man- 
									ter o handler ativo em buscas maiores
	Vinicius Porto		12/08/2013	adicionada a leitura progressiva tam-
									bem para o método fetchAllArray.
	*******************************************************************
 
=cut

use DBI;
use Scalar::Util qw(blessed);
use DbConn::Statement;
use DbConn::Exception;
use strict;

# public new
#
#
sub new 
{
	my $class 	= shift;
	my $self 	= {};
	
	$self->{_dbh}		= undef;
	$self->{_dbms}		= undef;
	$self->{_dbName}	= undef;
	$self->{_host}		= "127.0.0.1";
	$self->{_user}		= undef;
	
	# variaveis de instancia que permitem a leitura do resultset em etapas
	$self->{_activeQuery}	= undef;	# mantem o handler do statement ativo
	$self->{_lastSql}		= undef;	# ultimo sql executado
	
	bless($self,$class);
	
	return $self;
}

# public connect
#
#
sub connect
{
	my $self	= shift;
	my $connStr	= shift;
	my $user	= shift;
	my $pass	= shift;
	
	$self->{_dbh}	= DBI->connect("dbi:$connStr", $user, $pass, { AutoCommit => 1} ) or throw DbConn::Exception(1,DBI::errstr);
	$self->{_user}	= $user;
}

# public isConnected
#
# Verifica se há conexão com o DBMS.
#
# return 0 ou >0 (depende do driver de banco de dados)
sub isConnected
{
	my $self	=	shift;
	
	return $self->{_dbh}->ping() if(defined $self->{_dbh});
	return 0;
}

# public disconnect
#
# Finaliza conexão com DBMS.
sub disconnect
{
	my $self		=	shift;
	
	if($self->hasActiveQuery())
	{
		$self->finishActiveQuery();
	}
	
	if(defined $self->{_dbh})
	{
		$self->{_dbh}->disconnect() if($self->isConnected());
	}
}

# public eraseHandler
#
# Apaga o handler com o banco de dados. Utilizar somente com threads.
sub eraseHandler
{
	my $self	= shift;
	
	$self->{_dbh}	= undef;
}

# public DESTROY
#
#
sub DESTROY
{
	my $self	= shift;
	
	$self->disconnect();
}

# abstract public callProcedure
#
# Executa procedure.
sub callProcedure
{

}

# abstract public callFunction
# 
# Executa função.
sub callFunction
{
	
}

# abstract public createDatabase
#
#
sub createDatabase
{
	
}

# abstract public dropDatabase
#
#
sub dropDatabase
{
	
}

# public execute
#
# Executa instrução SQL.
#
# param $sql	instrução SQL
# param $bind
sub execute
{
	my $self	= shift;
	my $sql		= shift;
	my $bind	= shift;
	
	my $query	=	$self->_prepareStatement($sql);
	$query		=	$self->_executeQuery($query, $bind);
}

# public fetchRow
#
# Retorna hash referente ao primeiro registro da consulta.
#
# param $sql	instrução SQL
# return hash referente ao registro
sub fetchRow
{
	my $self	= shift;
	my $sql		= shift;
	my $bind	= shift;
	
	my $query	= $self->_prepareStatement($sql);
	$query		= $self->_executeQuery($query,$bind);
	
	return $query->fetchrow_hashref() or throw DbConn::Exception(4,$self->{_dbh}->errstr());
}

# public fetchOne
#
# Retorna único valor resultado da instrução sql.
#
# param $sql	instrução SQL
# return valor escalar
sub fetchOne
{
	my $self	= shift;
	my $sql		= shift;
	my $bind	= shift;
	
	my $query	= $self->_prepareStatement($sql);
	$query		= $self->_executeQuery($query,$bind);
	
	my @row		= $query->fetchrow_array() or throw DbConn::Exception(4,$self->{_dbh}->errstr());
	
	return $row[0] if(scalar(@row));
}

# public fetchAll
# 
# Retorna todo o resultado da instrução SQL, 
# 
# param $sql		instrução SQL
# param $maxRegs	numero máximo de registros a retornar (opcional)
# return  array com todos os registros estruturados em hashes
sub fetchAll
{
	my $self	= shift;
	my $sql		= shift;
	my $bind	= shift;
	my $maxRegs	= shift;	
	
	if((not defined $self->{_activeQuery}) || ($sql ne $self->{_lastSql}))
	{
		$self->{_activeQuery}	= $self->_prepareStatement($sql);
		$self->{_activeQuery}	= $self->_executeQuery($self->{_activeQuery},$bind);
		$self->{_lastSql}		= $sql;
	}
	
	my @rows	= ();
	
	while(my $row = $self->{_activeQuery}->fetchrow_hashref())
	{
		push @rows, $row;
		
		last if((defined $maxRegs) && (!--$maxRegs));
	}
	
	$self->{_activeQuery}	= undef	if(($maxRegs)||(not defined $maxRegs));	# reset da query ativa se todos os dados tiverem sido recuperados
	
	return \@rows;
}

# public fetchAllArray
#
# Retorna resultado como um array bidimensional
#
# param $sql		instrução SQL
# param $bind		array ref de binds
# param $maxRegs	número máximo de registros a se recuperar, deixando a consulta ativa, se necessário
# return referência à array com os registros retornados em referências de array
sub fetchAllArray
{
	my $self	= shift;
	my $sql		= shift;
	my $bind	= shift;
	my $maxRegs	= shift;	
	
	if((not defined $self->{_activeQuery}) || ($sql ne $self->{_lastSql}))
	{
		$self->{_activeQuery}	= $self->_prepareStatement($sql);
		$self->{_activeQuery}	= $self->_executeQuery($self->{_activeQuery},$bind);
		$self->{_lastSql}		= $sql;
	}
	
	my @rows	= ();
	
	# Obs.: antes que o indivíduo que ler o código pense que eu deveria utilizar o fetchrow_arrayref, que de todos
	# os métodos de recuperar registros do DBI é o mais rápido, informo que encontrei um estranho bug, onde sempre
	# me era retornado somente o primeiro registro de todo o resultset, além da informação ser read-only. Se descobrir
	# a razão desse bug, por favor, otimizar o código.
	while(my @row = $self->{_activeQuery}->fetchrow_array())
	{
		push @rows, \@row;
		
		last if((defined $maxRegs) && (!--$maxRegs));
	}
	
	$self->{_activeQuery}	= undef	if(($maxRegs)||(not defined $maxRegs));	# reset da query ativa se todos os dados tiverem sido recuperados
	
	return \@rows;
}

# public fetchColumn
#
# Recupera array referente a todos os registros recuperados de uma coluna.
#
# param $sql	instrução SQL
# return array de valores
sub fetchColumn
{
	my $self	= shift;
	my $sql		= shift;
	my $bind	= shift;
	
	my $query	= $self->_prepareStatement($sql);
	$query		= $self->_executeQuery($query,$bind);
	
	my @columnArray;
	
	while (my @row	= $query->fetchrow_array())
	{
		push(@columnArray,$row[0]);
	}
	
	return \@columnArray;
}

# public fetchPairs
#
# Recupera todos os registros e os transforma num hash, utilizando a primeira coluna como chave e a segunda coluna como
# valor. Todas as demais colunas são ignoradas.
#
# param $sql	dml
# param $bind	array ref de parametros para o dml
# return	hash ref com todos os pares recuperados pela consulta, no modelo Hash{col1} = col2	
sub fetchPairs
{
	my $self	= shift;
	my $sql		= shift;
	my $bind	= shift;
	
	my $query	= $self->_prepareStatement($sql);
	$query		= $self->_executeQuery($query,$bind);
	
	my %hashPairs	= ();
	
	while (my @row	= $query->fetchrow_array())
	{
		$hashPairs{$row[0]}	= $row[1];
	}
	
	return \%hashPairs;
}

# public fetchAllHashArray
#
# Recupera todos os registros e os transforma num hash, utilizando a primeira coluna como chave e a segunda coluna como
# um array com o registro completo.
#
# param $sql	dml
# param $bind	array ref de parametros para o dml
# return	hash ref com todos os pares recuperados pela consulta, no modelo Hash{col1} = col2	
sub fetchAllHashArray
{
	my $self	= shift;
	my $sql		= shift;
	my $bind	= shift;
	
	my $query	= $self->_prepareStatement($sql);
	$query		= $self->_executeQuery($query,$bind);
	
	my %hashPairs	= ();
	
	while (my @row	= $query->fetchrow_array())
	{
		$hashPairs{$row[0]}	= \@row;
	}
	
	return \%hashPairs;
}


# public hasActiveQuery
#
#
sub hasActiveQuery
{
	my $self	= shift;
	return defined $self->{_activeQuery};
}

# public finishActiveQuery
#
# finaliza a consulta ativa se a mesma estiver ativa
sub finishActiveQuery
{
	my $self	= shift;
	$self->{_activeQuery}->finish() if($self->hasActiveQuery());
}

# public beginTransaction
#
# Indica que as instruções SQL não serão auto-comitáveis
sub beginTransaction
{
	my $self	=	shift;
	
	$self->{_dbh}->begin_work();
}

# public insert
# 
# Insere row em tabela do SGBD.
#
# param $table	nome da tabela
# param %insert	hash de valores a serem inseridos (chave igual ao nome da coluna)
sub insert
{
	my $self	=	shift;
	my $table	=	shift;
	my $insert	=	shift;

	my $sql			= "INSERT INTO $table ";
	my @columns		= ();
	my @positions	= ();
	my @values		= ();
	
	throw DbConn::Exception(5) if(not defined $insert);
	
	foreach my $column (keys %{$insert})
	{
		push @columns, $column;
		push @positions, "?";
		push @values, $self->_formatValue($$insert{$column});
	}	
	
	$sql	.=	"(".join(", ",@columns).") VALUES (".join(", ",@positions).")";
	
	my $query	=	$self->_prepareStatement($sql);
	$self->_executeQuery($query,\@values);
}

# public insertRows
#
# 
sub insertRows
{
	my $self	= shift;
	my $table	= shift;
	my $rows	= shift;
	
	throw DbConn::Exception(5) if(not defined $rows);
	
	if(scalar(@{$rows}))
	{
		my $sql			= "INSERT INTO $table ";
		my @columns		= ();
		my @positions	= ();
		my $fst			= 1;
		my $query;
		
		foreach my $row (@{$rows})
		{
			if($fst-- > 0)
			{
				foreach my $column (keys %{$row})
				{
					push @columns, $column;
					push @positions, "?";
				}
				
				$sql	.=	"(".join(", ",@columns).") VALUES (".join(", ",@positions).")";
				$query	=	$self->_prepareStatement($sql);
			}
			
			my @values	= ();
			
			foreach my $column (@columns)
			{
				push @values, $self->_formatValue($$row{$column});
			}
			
			$self->_executeQuery($query,\@values);
		}
	}
}

# public delete
#
# Deleta registros de uma tabela.
#
# param $tableName	nome da tabela
# param $where		clásula where (opcional)
sub delete
{
	my $self		= shift;
	my $tableName	= shift;
	my $where		= shift;

	my $sql			= "DELETE FROM $tableName";
	my @whereArray	= ();
	my @values		= ();
	
	if(defined $where)
	{
		foreach my $column (keys %{$where})
		{
			push @whereArray, "$column = ?";
			push @values, $self->_formatValue($$where{$column});
		}
	}
	
	$sql	.=	" WHERE ".join(" AND ", @whereArray) if(scalar(@whereArray)); 
	
	my $query	=	$self->_prepareStatement($sql);
	$self->_executeQuery($query,\@values);
}

# public update
#
# Atualiza registros de uma tabela.
#
# param $table	nome da tabela
# param %update	hash com a atualização (chave equivale ao nome da coluna)
# param $where	cláusula where
sub update
{
	my $self	= shift;
	my $table	= shift;
	my $update	= shift;
	my $where	= shift;
	
	my $sql			= "UPDATE $table SET ";
	my @updateArray	= ();
	my @whereArray	= ();
	my @values		= ();
	
	throw DbConn::Exception() if(not defined $update);
	
	foreach my $column (keys %{$update})
	{
		push @updateArray, $column." = ?";
		push @values, $self->_formatValue($$update{$column});
	}
	
	$sql	.=	join(", ",@updateArray);
	
	if(defined $where)
	{
		foreach my $column (keys %{$where})
		{
			push @whereArray, $column." = ?";
			push @values, $self->_formatValue($$where{$column});
		}
		
		$sql .= " WHERE ".join(" AND ",@whereArray);
	}

	my $query	=	$self->_prepareStatement($sql);
	$self->_executeQuery($query, \@values);	
}

# public commit
#
# Commit da transação.
sub commit
{
	my $self	=	shift;
	$self->{_dbh}->commit();
}

# public rollback
#
# Rollback da transação.
sub rollback
{
	my $self	=	shift;
	$self->{_dbh}->rollback();
}

# protected _prepareStatement
#
# Interpreta a consulta e retorna o handler.
#
# param $sql	instrução SQL
# return $query
sub _prepareStatement
{
	my $self	=	shift;
	my $sql		=	shift;
	
	my $query	=	$self->{_dbh}->prepare($sql);
	throw DbConn::Exception(2, $self->{_dbh}->errstr()) if (not defined $query);
	
	return $query; 	
}

# protected _executeQuery
#
# Executa instrução SQL.
#
# @param $query
# @return $query
sub _executeQuery
{
	my $self	= shift;
	my $query	= shift;	
	my $bind	= shift;	
	
	$bind	= [] if(not defined $bind);
	
	$query->execute(@{$bind}) or throw DbConn::Exception(3, $self->{_dbh}->errstr());
	
	return $query;
}

#
#
#
sub _formatValue
{
	my $self	= shift;
	my $value	= shift;
	
	my $formattedValue	= "";
	
	if((defined $value) && ($value =~ /HASH/) && (blessed $value eq 'DbConn::Statement'))
	{
		$formattedValue	= $value->toString();
	}
	else
	{
		$formattedValue	= $value;
	}
	
	return $formattedValue;
}

#
# getters
#

sub getUser
{
	my $self	= shift;
	return $self->{_user};
}

sub getHost
{
	my $self	= shift;
	return $self->{_host};
}

sub getDbName
{
	my $self	= shift;
	return $self->{_dbName};
}

sub getDbms
{
	my $self	= shift;
	return $self->{_dbms};
}

1;