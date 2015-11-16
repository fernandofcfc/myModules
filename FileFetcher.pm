package FileFetcher;

=for comment

	*******************************************************************
	module:		FileFetcher
	package:	FileFetcher
	author:		Vinicius Porto Lima
	date:	
	version
	
	description:
	
	*******************************************************************
	change log
	author:				date:			description:
	
	*******************************************************************
	
=cut

use Time::Local;
use Util;
use FileFetcher::Exception;
use FileFetcher::Remote::Secure;
use strict;

use constant CONN_SECURE	=> "secure";
use constant CONN_INSECURE	=> "insecure";
use constant DEFAULT_DAYS	=> 3;
use constant LIMIT_DAYS		=> 15;

# public new
#
#
sub new 
{
	my $class 	= shift;
	my $self 	= {};
	
	$self->{_remoteDir}		= shift;	
	$self->{_localDir}		= shift;
	$self->{_controlFile}	= shift;	# opcional
	
	throw FileFetcher::Exception(0,$self->{_localDir}." não existe ou não está acessível") if(! -e $self->{_localDir});
	
	$self->{_oldDownloaded}		= {};	# Hash{file_name} = unix timestamp
	$self->{_newDownloaded}		= {};	# Hash{file_name} = unix timestamp
	$self->{_remoteFilesList}	= {};	# Hash{file_name} = unix timestamp
	
	$self->{_remote}	= undef;	# objeto de conexão
	
	$self->{_ip}		= undef;
	$self->{_user}		= undef;
	
	bless($self,$class);
	
	$self->_readControlFile() if(defined $self->{_controlFile});
	
	return $self;
}

# public startRemoteHandler
#
# inicializa conexão com file system de servidor remoto.
#
# param $ip		endereço ip do servidor
# param $user	usuário para acessar servidor remoto
# param $type	tipo de conexão (default: secure)
#
# Obs.: para que a conexão seja realizada, é obrigatório que o cliente e o servidor possuam relação de confiança.
sub startRemoteHandler
{
	my $self	= shift;
	my $ip		= shift;
	my $user	= shift;
	my $type	= shift;
	
	$type	= CONN_SECURE if(not defined $type);
	
	if($type eq CONN_SECURE)
	{
		$self->{_remote}	= FileFetcher::Remote::Secure->new($ip, $user);	# prepara um objeto para configurar uma conexão segura
	}
	else
	{
		throw FileFetcher::Exception(1,$type);
	}
}

# public fetchNewFiles 
#
#
sub fetchNewFiles
{
	my $self		= shift;
	my $fileRegex	= shift;	
	my $retroStart	= shift;	 
	my $retroEnd	= shift;
	
	# recupera lista de todos os arquivos remotos
	$self->_buildRemoteFilesList($fileRegex);
	my %remoteFiles	= ();
	my %toDownload	= ();
	
	my @downloadedPath	= ();
	
	my $startTimeStamp	= 0;
	my $endTimeStamp	= 0;
	
	$startTimeStamp	= time() - ($retroStart*3600) 	if((defined $retroStart) && ($retroStart > 0));
	$endTimeStamp	= time() - ($retroEnd*3600)		if((defined $retroEnd) && ($retroEnd > 0));
	
	# recupera arquivos que estão no intervalo especificado
	foreach my $fileName (keys %{$self->{_remoteFilesList}})	
	{
		my $unixTimeStamp	= $self->{_remoteFilesList}->{$fileName};
		$remoteFiles{$fileName}	= $unixTimeStamp if(	($startTimeStamp <= $endTimeStamp) 	&& 
														($unixTimeStamp > $startTimeStamp) 	&&
														(($endTimeStamp && ($unixTimeStamp < $endTimeStamp)) || (!$endTimeStamp))); 
	}
	
	# desconsidera aqueles que já foram baixados
	foreach my $fileName (keys %remoteFiles)
	{
		$toDownload{$fileName}	= $remoteFiles{$fileName} if(not exists $self->{_oldDownloaded}->{$fileName});
	}
	
	# download dos novos arquivos 
	foreach my $fileName (keys %toDownload)
	{
		my $remotePath	= $self->{_remoteDir}."/$fileName";
		my $localPath	= $self->{_localDir}."/$fileName";
		
		$self->{_remote}->getFile($remotePath,$localPath);
		throw FileFetcher::Exception(2, $fileName) if(! -f $localPath);
		push @downloadedPath, $localPath;
	}
	
	$self->{_newDownloaded}	= \%toDownload;
	
	return \@downloadedPath;
}

# public fetchFile
#
# 
sub fetchFile
{
	my $self		= shift;
	my $fileName	= shift;
	
	throw FileFetcher::Exception(4) if(not defined $self->{_remote});	# lança exceção se o objeto de conexão não está definido
	my $remotePath	= $self->{_remoteDir}."/$fileName";
	my $localPath	= $self->{_localDir}."/$fileName";
	
	$self->{_remote}->getFile($remotePath,$localPath);	# copia o arquivo
	throw FileFetcher::Exception(2, $fileName) if(! -f $localPath);
	
	return $localPath;
}

# public removeRemoteOldFiles
#
#
sub removeRemoteOldFiles
{
	my $self		= shift;
	my $retroDays	= shift;
	my $fileRegex	= shift;
	
	$self->_buildRemoteFilesList($fileRegex) if(defined $fileRegex);
	$retroDays	= DEFAULT_DAYS if(not defined $retroDays);
	$retroDays	= LIMIT_DAYS if($retroDays > LIMIT_DAYS);
	
	my $limitTimeStamp	= time() - ($retroDays * 86400);
	
	foreach my $fileName (keys %{$self->{_remoteFilesList}})
	{
		if($self->{_remoteFilesList}->{$fileName} < $limitTimeStamp)	# deleta arquivo se antigo
		{
			$self->{_remote}->cmd("rm -f ".$self->{_remoteDir}."/$fileName");
		}
	}
}

# public cacheDownloadedFiles
#
#
sub cacheDownloadedFiles
{
	my $self	= shift;
	
	throw FileFetcher::Exception(5) if(not defined $self->{_controlFile});
	
	my @cache			= ();
	my $limitTimeStamp	= time() - ((LIMIT_DAYS+1) * 86400);
	
	foreach my $fileName (keys %{$self->{_oldDownloaded}})
	{
		if($self->{_oldDownloaded}->{$fileName} >= $limitTimeStamp)
		{
			push @cache, [$fileName, $self->{_oldDownloaded}->{$fileName}];
		}
	}
	
	foreach my $fileName (keys %{$self->{_newDownloaded}})
	{
		push @cache, [$fileName, $self->{_newDownloaded}->{$fileName}];	
	}
	
	Util::writeCacheFile($self->{_controlFile}, \@cache);
}

# public removeLocalFiles
#
#
sub removeLocalFiles
{
	my $self		= shift;
	
	system("find ".$self->{_localDir}." -type f -exec rm -f {} \\;") == 0 or throw FileFetcher::Exception(3);
}

# public getRemoteFileList
#
# 
sub getRemoteFilesList
{
	my $self		= shift;
	my $fileRegex	= shift;
	
	$self->_buildRemoteFilesList($fileRegex) if(defined $fileRegex);
	
	my @filesList	= keys(%{$self->{_remoteFilesList}});
	return \@filesList;
}

# private _buildRemoteFilesList
#
#
sub _buildRemoteFilesList
{
	my $self		= shift;
	my $fileRegex	= shift;
	
	throw FileFetcher::Exception(4) if(not defined $self->{_remote});
	
	my $listFilesCmd	= "ls -lc --time-style=full-iso $self->{_remoteDir}"; # comando que lista os arquivos do diretório adicionado do timestamp do último acesso ao arquivo
	my $externalCmd		= "| awk '{print \$6\" \"\$7\";\"\$9}'";	# mostra a data e o horário da última alteração e o nome do arquivo
	
	my $output			= $self->{_remote}->cmd($listFilesCmd,$externalCmd);
	
	foreach my $line (split("\n",$output))
	{
		if($line =~ /$fileRegex/)
		{
			my ($timeStamp, $fileName)	= split(";", $line);
			my ($year,$month,$day,$hour,$minute,$second)	= $timeStamp	=~ /(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})/;
			
			my $unixTimeStamp	= Util::unixTime($year,$month,$day,$hour,$minute,$second); 
			
			$self->{_remoteFilesList}->{$fileName}	= $unixTimeStamp;
		}
	}
}

# private _readControlFile
#
#
sub _readControlFile
{
	my $self	= shift;
	
	if(-f $self->{_controlFile})
	{
		my $array	= Util::readCacheFile($self->{_controlFile});
		
		foreach my $row	(@{$array})
		{
			$self->{_oldDownloaded}->{$$row[0]}	= $$row[1];
		}
	}
}

1;