package Logger;

=for comment

	*******************************************************************
	module:		Logger
	package:	Logger
	author:		Vinicius Porto Lima
	date:		
	version:
	
	description:
	
	*******************************************************************
	change log
	author:				date:			description:
	Vinicius Porto		23/07/2013		Adição da lógica de compartilhamento
										para uso com threads
	*******************************************************************
	
=cut

use Logger::Exception;
use Logger::Log::Simple;
use Logger::Log::Excpt;
use Logger::Log::Severity;
use Util;
use threads;
use threads::shared;
use strict;

use constant DEF_LOG_PREFIX	=> "exec";
use constant DEF_EXC_PREFIX	=> "exception";
use constant LOG_SUFFIX	=> ".log";

# variáveis
my @_logs		 : shared = ();	# array compartilhado que armazena todos os logs 
my @_exceptions	 : shared = (); # array compartilhado que armazena todas as exceções

# public static addLog
#
# Adiciona log na memória.
#
# param $text		texto do log
# param $severity	codigo de severidade do log (default Logger::Log::Severity::INFO_LVL)
sub addLog
{
	my $text		= shift;
	my $severity	= shift;
	
	$severity	= Logger::Log::Severity::INFO_LVL if(not defined $severity);
	
	my $log	= Logger::Log::Simple->new();
	$log->setText($text);
	$log->setSeverity($severity);
	
	push @_logs, shared_clone($log);
}

# public static addException
#
# Adiciona exceção na memória.
#
# param $text		texto da exceção
# param $value		código da exceção
# param $stacktrace	stacktrace
sub addException
{
	my $text		= shift;
	my $value		= shift;
	my $stacktrace	= shift;
	
	my $excpt	= Logger::Log::Excpt->new($text, $value, $stacktrace);
	
	push @_exceptions, shared_clone($excpt);
	
	my $log	= Logger::Log::Simple->new();
	$log->setText($text." (".$excpt->getToken().")");
	$log->setSeverity(Logger::Log::Severity::EXCP_LVL);
	
	push @_logs, shared_clone($log);
}

# public static dumpLogs
#
# Salva todos os logs em um arquivo.
#
# param $dir	nome do diretório
# param $prefix	prefixo do arquivo (default Logger::DEF_LOG_PREFIX)
# throws Util::Exception
sub dumpLogs
{
	my $dir		= shift;
	my $prefix	= shift;
	
	$prefix		= DEF_LOG_PREFIX if(not defined $prefix);
	
	my $logPath	= $dir."/".lc($prefix."_".Util::timestampFormattedString(time(),"\%Y\%m\%d_\%H\%M\%S").LOG_SUFFIX);
	my $content	= "";
	
	foreach my $log	(@_logs)
	{
		$content	.= $log->getTimestampString()."\t".$log->getSeverity()."\t".$log->getText()."\n";
	}
	
	@_logs	= ();
	Util::stringToFile($logPath, $content);
}

# public static dumpLogsReturn
#
# Salva todos os logs em um arquivo e retorna o nome do arquivo.
#
# param $dir	nome do diretório
# param $prefix	prefixo do arquivo (default Logger::DEF_LOG_PREFIX)
# throws Util::Exception
sub dumpLogsReturn
{
	my $dir		= shift;
	my $prefix	= shift;
	
	$prefix		= DEF_LOG_PREFIX if(not defined $prefix);
	
	my $logPath	= $dir."/".lc($prefix."_".Util::timestampFormattedString(time(),"\%Y\%m\%d_\%H\%M\%S").LOG_SUFFIX);
	my $content	= "";
	
	foreach my $log	(@_logs)
	{
		$content	.= $log->getTimestampString()."\t".$log->getSeverity()."\t".$log->getText()."\n";
	}
	
	@_logs	= ();
	Util::stringToFile($logPath, $content);
	
	return $logPath;
}

# public static dumpExceptions
#
# Salva cada exceção em um arquivo distinto.
#
# param $dir	nome do diretório
# param $prefix	prefixo do arquivo (default Logger::DEF_EXC_PREFIX)
# throws Util::Exception
sub dumpExceptions
{
	my $dir		= shift;
	my $prefix	= shift;
	
	$prefix		= DEF_EXC_PREFIX if(not defined $prefix); 
	
	foreach my $excpt (@_exceptions)
	{
		my $excptPath	= $dir."/".lc($prefix."_".$excpt->getToken().LOG_SUFFIX);
		
		my $content		= "CODE:	".$excpt->getValue()."\n"
						. "TEXT:	".$excpt->getText()."\n"
						. "STACKTRACE:\n".$excpt->getStacktrace()."\n";
						
		Util::stringToFile($excptPath, $content);
	}
	
	@_exceptions	= ();
}

1;