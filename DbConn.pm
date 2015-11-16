package DbConn;

=for comment

	*******************************************************************
	module:		DbConn
	package:	DbConn
	author:		Vinicius Porto Lima
	date:
	version:	1.1
	
	description:	Static module that allows one to choose a db handler
					object (DbConn::Abstract) by DBMS. It can keep a 
					session db handler for the whole execution, even when
					using threads, where DBI handlers cannot be shared. 
	
	*******************************************************************
	change log
	author:				date:			description:
	Vinicius Porto		01/07/2013		added class attribute $_sessionDbConn
	Vinicius Porto		04/07/2013		added class attribs $_sharedDbConn
										and %_connParams
	*******************************************************************
	
=cut

use DbConn::PostgreSQL;
use DbConn::SQLServer;
use DbConn::Exception;
use threads;
use threads::shared;
use strict;

# constantes
use constant POSTGRESQL	=> "PGSQL";
use constant SQLSERVER	=> "SQLSERVER";

# class attributes
my $_sessionDbConn;
my $_sharedDbConn;
my $_dbms : shared;

my %_connParams	: shared	= ();

# public static getDbmsConn
#
#
sub getDbmsConn
{
	my $dbms	= shift;
	
	if($dbms	eq POSTGRESQL)
	{
		return DbConn::PostgreSQL->new();
	} 
	elsif($dbms	eq SQLSERVER)
	{
		return DbConn::SQLServer->new();
	}
	else
	{
		throw DbConn::Exception(0);
	}
}

# public static startSessionInstance
#
#
sub startSessionInstance
{
	my $dbms		= shift;
	my $connParams	= shift;
	my $withThreads	= shift;	
	
	if($withThreads)
	{
		$_dbms			= $dbms;
		%_connParams	= %{$connParams};
		
		startSharedInstance();
	}
	else
	{
		$_sessionDbConn	= getDbmsConn($dbms);
		$_sessionDbConn->connect($connParams);
	}	
}

# public static getSessionInstance
#
#
sub getSessionInstance
{
	my $dbms		= shift;
	my $connParams	= shift;
	my $withThreads	= shift;	
	
	if($withThreads)
	{
		$_dbms			= $dbms;
		%_connParams	= %{$connParams};
		
		startSharedInstance();
	}
	else
	{
		$_sessionDbConn	= getDbmsConn($dbms);
		$_sessionDbConn->connect($connParams);
	}
	return $_sessionDbConn;
}

# public static sessionInstance
#
#
sub sessionInstance
{
	return $_sessionDbConn;
}

# public static startSharedInstance
#
#
sub startSharedInstance
{
	$_sharedDbConn->eraseHandler() if(defined $_sharedDbConn);
	
	$_sharedDbConn	= getDbmsConn($_dbms);
	$_sharedDbConn->connect(\%_connParams);
}

# public static sharedInstance
#
#
sub sharedInstance
{
	return $_sharedDbConn;
}

1;