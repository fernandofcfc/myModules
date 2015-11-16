package DbConn::PostgreSQL::Pgloader;

=for comment

	*******************************************************************
	module:		DbConn
	package:	DbConn::PostgreSQL::Pgloader
	author:		Vinicius Porto Lima
	date:		05/07/2013
	version:	0.1
	
	description:
	
	Código xexelento de carga em banco PostgreSQL utilizando o pgloader
	
	*******************************************************************
	change log
	author:				date:			description:
	
	*******************************************************************
	
=cut

# TODO fazer um código de vergonha

use DbConn::PostgreSQL::PgLoader::Exception;
use Util;
use strict;

#
# constants
#
use constant PGLOADER_CMD		=> "pgloader";
use constant LOADING_PREFIX		=> "LOADER_";

use constant DEFAULT_DIR		=> "/tmp";
use constant DEFAULT_LOGFILE		=> "pgloader.log";
use constant DEFAULT_PORT		=> 5432;
use constant DEFAULT_PASS		=> "none";

use constant CONF_SUFFIX		=> ".conf";
use constant DATA_SUFFIX		=> ".data";
use constant LOG_SUFFIX			=> ".log";
use constant REJ_SUFFIX			=> ".rej";

# valores default do arquivo de configurações
use constant LOG_MIN_MESSAGES		=> "WARNING";
use constant CLIENT_MIN_MESSAGES	=> "WARNING";
use constant CLIENT_ENCODING		=> "latin1";
use constant COPY_EVERY			=> 500;
use constant COMMIT_EVERY		=> 500;

# valores default do template
use constant TEMPLATE_NAME		=> "default_template";
use constant FORMAT			=> "text";
use constant FIELD_SEP			=> "~";

# public new
#
#
sub new
{
	my $class 	= shift;
	my $self 	= {};

	$self->{_host}		= shift;			
	$self->{_dbname}	= shift;
	$self->{_user}		= shift;
	$self->{_pass}		= shift;	
	$self->{_port}		= shift;
	
	$self->{_pass}		= DEFAULT_PASS if(not defined $self->{_pass});
	$self->{_port}		= DEFAULT_PORT if(not defined $self->{_port});

	$self->{_workingDir}	= DEFAULT_DIR;
	$self->{_logsDir}	= DEFAULT_DIR;
	
	bless($self,$class);

	return $self;
}

# public load
#
#
sub load
{
	my $self	= shift;
	my $table	= shift;
	my $rows	= shift;
	
	my $loadingName		= LOADING_PREFIX.Util::token();
	my $confPath		= $self->{_workingDir}."/".$loadingName.CONF_SUFFIX;	# nome do arquivo de configurações
	my $dataPath		= $self->{_workingDir}."/".$loadingName.DATA_SUFFIX;	# nome do arquivo de dados
	
	my @cols			= sort keys(%{$$rows[0]});  
	
	# cria o arquivo de configurações
	Util::stringToFile(	$confPath, 
						$self->_header($loadingName).$self->_template().$self->_loadingSection($loadingName, $table, \@cols));
	
	# cria o arquivo de dados
	open FILE, ">$dataPath";
	
	foreach my $row (@{$rows})
	{
		my @line	= ();
		
		foreach my $col(@cols)
		{
			my $value	= $$row{$col};
			
			if((not defined $value) or ($value eq ""))	# nulo
			{
				$value	= "";
			}
			else
			{
				my $fieldSep	= FIELD_SEP;
				$value	=~ s/$fieldSep//g;
			}
			
			push @line, $value;
		}
		
		print FILE join(FIELD_SEP,@line)."\n";
	}
	
	close FILE;
	
	# executando o pgloader
	my $cmd	= PGLOADER_CMD." -c '$confPath' '$loadingName' > /dev/null 2>&1";
	system("$cmd") == 0 or throw DbConn::PostgreSQL::PgLoader::Exception(101,"Loading $loadingName");
	Util::copyFile(DEFAULT_DIR."/".DEFAULT_LOGFILE,$self->{_logsDir}."/$loadingName".LOG_SUFFIX) if(-f DEFAULT_DIR."/".DEFAULT_LOGFILE);
	
	return $loadingName;	
}

# private _header
# 
#
sub _header
{
	my $self	= shift;
	my $name	= shift;
	
	return "
[pgsql]
host = ".$self->{_host}."
port = ".$self->{_port}."
base = ".$self->{_dbname}."
user = ".$self->{_user}."
pass = ".$self->{_pass}."
log_min_messages    = ".LOG_MIN_MESSAGES."
client_min_messages = ".CLIENT_MIN_MESSAGES."
client_encoding = '".CLIENT_ENCODING."'
copy_every      = ".COPY_EVERY."
commit_every    = ".COMMIT_EVERY."
";
}

# private _template
#
#
sub _template
{
	my $self	= shift;
	
	return "
[".TEMPLATE_NAME."]
template     = True
format       = ".FORMAT."
field_sep    = ".FIELD_SEP."
";
}

# private _loadingSection
#
#
sub _loadingSection
{
	my $self	= shift;
	my $name	= shift;
	my $table	= shift;
	my $cols	= shift;
	
	return "
[$name]
use_template	= ".TEMPLATE_NAME."
table           = $table
filename        = ".$self->{_workingDir}."/$name".DATA_SUFFIX."
columns         = ".join(",",@{$cols})."
reject_log   	= ".$self->{_logsDir}."/$name".REJ_SUFFIX.LOG_SUFFIX."
reject_data  	= ".$self->{_logsDir}."/$name".REJ_SUFFIX."
";
}

#
# getters and setters
#
sub setWorkingDir
{
	my $self		= shift;
	my $workingDir	= shift;
	
	DbConn::PostgreSQL::PgLoader::Exception(101, "directory $workingDir does not exist or is not avaiable") if(! -d $workingDir);
	$self->{_workingDir}	= $workingDir;
}

sub setLogsDir
{
	my $self		= shift;
	my $logsDir		= shift;
	
	DbConn::PostgreSQL::PgLoader::Exception(101, "directory $logsDir does not exist or is not avaiable") if(! -d $logsDir);
	$self->{_logsDir}	= $logsDir;
}

1;
