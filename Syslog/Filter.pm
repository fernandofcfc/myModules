package Syslog::Filter;

use Syslog::Filter::PgLog::ConnectionAuthorized;
use Syslog::Filter::PgLog::Disconnection;
use Syslog::Filter::PgLog::Statement;
use Syslog::Filter::PgLog::Duration;
use Syslog::Filter::PgLog::Error;
use Syslog::Filter::PgLog::Fatal;
use Syslog::Filter::PgLog::Warning;
use Syslog::Filter::PgLog::Panic;
use Syslog::Filter::Exception;
use strict;

my %_filterMap	=	(	"pglog_connection_authorized"	=> Syslog::Filter::PgLog::ConnectionAuthorized->new(),
						"pglog_disconnection"			=> Syslog::Filter::PgLog::Disconnection->new(),
						"pglog_statement"				=> Syslog::Filter::PgLog::Statement->new(),
						"pglog_duration"				=> Syslog::Filter::PgLog::Duration->new(),
						"pglog_error"					=> Syslog::Filter::PgLog::Error->new(),
						"pglog_fatal"					=> Syslog::Filter::PgLog::Fatal->new(),
						"pglog_warning"					=> Syslog::Filter::PgLog::Warning->new(),
						"pglog_panic"					=> Syslog::Filter::PgLog::Panic->new());
	
##
# public static select
##						
sub select
{
	my $filterName	= shift;
	
	throw Syslog::Filter::Exception(11, $filterName) if(not exists $_filterMap{$filterName});
	
	return $_filterMap{$filterName};
}

##
# public static filterList
##
sub filterList
{
	my @filterList	= keys %_filterMap; 
	
	return \@filterList;
}

1;