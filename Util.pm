package Util;


=for comment

 Module Util
 Autor: 	Vinicius Porto Lima
 Versão:	0.1

 Descrição:
 
 Modificações
 Autor:				Data:			Descrição:
 Vinicius Porto	03/04/2013		Verifica se seção do arquivo .ini contém todos os campos listados
									em array passado como parâmetro para o sub readIniFileSection
 Pedro Ilton		08/04/2013		Adicionada a função decompressGzipFile
									
=cut

use Util::Exception;
use Date::Format;
use Time::Local;
use File::Copy qw(copy);
use File::Path qw(remove_tree);
use File::Basename;
use Digest::MD5 qw(md5_hex);
use Config::IniFiles;
use strict;

my $_inFileItemSeparator	= ";";

##
# public static makeDir
##
sub makeDir
{
	my $dir	= shift;
	
	mkdir $dir or throw Util::Exception(1,$dir)
		if(! -d $dir);
}

##
# public static listDirFiles
#
# param $dir		nome do diretório
# param $pattern	padrão de arquivos a ser listado
# return			lista de arquivos que obedecem ao padrão informado
##
sub listDirFiles
{
	my $dir		= shift;
	my $pattern	= shift;
	
	my @filesList	= ();
	
	opendir DIR, $dir or throw Util::Exception(7, $dir);
	
	while(my $file	= readdir(DIR))
	{
		next if(! -f $dir."/".$file);
		push @filesList, $file if($file =~ /$pattern/);
	}
	
	closedir DIR;
	
	return \@filesList;
}

##
# public static listDirFilesCompletePath
#
# param $dir            nome do diretï¿½rio
# param $pattern        padrï¿½o de arquivos a ser listado
# return                lista de arquivos que obedecem ao padrï¿½o informa, onde o nome do arquivo eh seu caminho completo
##
sub listDirFilesCompletePath
{
        my $dir         = shift;
        my $pattern     = shift;

        my @filesList   = ();

        opendir DIR, $dir or throw Util::Exception(7, $dir);

        while(my $file  = readdir(DIR))
        {
                next if(! -f $dir."/".$file);
                push @filesList, $dir."/".$file if($file =~ /$pattern/);
        }

        closedir DIR;

        return \@filesList;
}



##
# public static listDirSubDirs
#
# param $dir		nome do diretório
# param $pattern	padrão de subdiretórios (opcional)
# return 			lista de subdiretórios
##
sub listDirSubDirs
{
	my $dir		= shift;
	my $pattern	= shift;
	
	my @subDirsList	= ();
	
	opendir DIR, $dir or throw Util::Exception(7, $dir);
	
	while(my $subdir	= readdir(DIR))
	{
		next if(! -d $dir."/".$subdir);
		next if(($subdir eq ".")||($subdir eq ".."));
		next if((defined $pattern) && !($subdir =~ /$pattern/));
		
		push @subDirsList, $subdir;
	}
	
	closedir DIR;
	
	return \@subDirsList;	
}

##
# public static cleanDir
#
# param $dir	nome do diretório
##
sub cleanDir
{
	my $dir	= shift;
	
	opendir DIR, $dir or throw Util::Exception(7, $dir);
	
	while(my $subdirOrFile	= readdir(DIR))
	{
		next if(($subdirOrFile eq ".") || ($subdirOrFile eq ".."));
		my $path	= $dir."/".$subdirOrFile;
		
		if(-f $path)
		{
			removeFile($path);
		}
		elsif(-d $path)
		{
			removeDir($path);
		}
	}
	
	closedir DIR;
}

##
# public static removeDir
##
sub removeDir
{
	my $dir	= shift;
	
	remove_tree($dir) or throw Util::Exception(2,$dir);
}

##
# public static removeFile
##
sub removeFile
{
	my $filePath	= shift;
	
	unlink $filePath if(-e $filePath);
}

# public static copyFile
#
#
sub copyFile
{
	my $sourceFilePath	= shift;
	my $destinyFilePath	= shift;
	
	copy($sourceFilePath, $destinyFilePath) or throw Util::Exception(3,"copy $sourceFilePath to $destinyFilePath");
}

# public static copyFileToDir
#
#
sub copyFileToDir
{
	my $sourceFilePath	= shift;
	my $destinyDir		= shift;
	
	copyFile($sourceFilePath,$destinyDir."/".getFileName($sourceFilePath));
}

##
# public static gzipFile
#
# param $filePath
# return	file path para o arquivo gzipado
##
sub gzipFile
{
	my $filePath	= shift;
	
	system("gzip $filePath") == 0 or throw Util::Exception(4,"file $filePath");
	
	return $filePath.".gz"; 
}

##
# public static decompressGzipFile
#
# param $filePath
# return	file path para o arquivo descomprimido
##
sub decompressGzipFile
{
	my $filePath	= shift;
	
	system("gzip -df $filePath") == 0 or throw Util::Exception(8,"file $filePath");
	
	return substr $filePath, 0, -3;	# file path do arquivo sem ".gz"
}

##
# public static removeOldFiles
##
sub removeOldFiles
{
	my $dirPath	= shift;
	my $days	= shift;
	
	system("find $dirPath -type f -mtime +$days -exec rm -f {} \\;") == 0 or throw Util::Exception(5,"dir $dirPath (mtime $days)");
}

##
# public static readCacheFile
#
# param $filePath	full path do arquivo
# return	array ref de matriz de itens do arquivo
##
sub readCacheFile
{
	my $filePath	= shift;
	my @array		= ();
	
	open FILE, $filePath or throw Util::Exception(6, $filePath);
	
	while(my $line	= <FILE>)
	{
		chomp($line);
		
		my @items	= split($_inFileItemSeparator, $line);
		
		push @array, \@items;
	}
	
	close FILE;
	
	return \@array;
}

##
# public static readFile
#
# param $filePath	full path do arquivo
# return		array com linhas do arquivo
##
sub readFile
{
	my $filePath	= shift;
	my @array	= ();
	
	open FILE, $filePath or throw Util::Exception(6, $filePath);
	
	while(my $line	= <FILE> )
	{
		if ( $line =~ /^(?!\#|\n)/ ) { # ignora linhas iniciadas por # ou sem conteudo
			chomp($line);
			push @array, $line;
		}
	}
	close FILE;
	
	return \@array;
}

##
# public writeCacheFile
##
sub writeCacheFile
{
	my $filePath	= shift;
	my $matrix		= shift;
	
	open FILE, ">$filePath" or throw Util::Exception(6, $filePath);
	
	foreach my $array(@{$matrix})
	{
		print FILE join($_inFileItemSeparator,@{$array})."\n";
	}
	
	close FILE;
}

# public static fileToString
#
# param $filePath	path do arquivo
# param $offset		linha inicial
# param $length		número de linhas
sub fileToString
{
	my $filePath	= shift;
	my $offset		= shift;
	my $length		= shift;
	
	my $string		= "";
	my $indx		= 0;
	
	$offset	= 0 if(not defined $offset);
	
	
	open FILE, $filePath or throw Util::Exception(6, $filePath);
	
	while(my $line	= <FILE>)
	{
		last if((defined $length) && ($indx >= ($offset+$length)));
		next if($indx++ < $offset);
		
		$string	.= $line 
	}
	
	close FILE;
	
	return $string;
}

# public stringToFile
#
#
sub stringToFile
{
	my $filePath	= shift;
	my $string		= shift;
	
	open FILE, ">$filePath" or throw Util::Exception(6, $filePath);
	print FILE $string;
	close FILE;
}

# public appendStringToFile
#
#
sub appendStringToFile
{
	my $filePath	= shift;
	my $string		= shift;
	
	system("touch $filePath");	# cria o arquivo
	
	open FILE, ">>$filePath" or throw Util::Exception(6, $filePath);	# append no arquivo
	print FILE $string;
	close FILE;
}

# public fileTotalLines
#
#
sub fileTotalLines
{
	my $filePath	= shift;
	
	my $count		= 0;
	
	if(-f $filePath)
	{
		$count	= `cat $filePath | wc -l`;
		chomp($count);
		$count	= int($count);
	} 
	
	return $count;
}

##
# public static getDirName
#
# param $path	path do arquivo do qual se deseja saber o diretório
# return	diretório contido no path
##
sub getDirName
{
	my $path	= shift;
	return dirname($path);
}

##
# public static getFileName
#
# param $path	path do arquivo do qual se deseja saber o nome do arquivo somente
# return	nome do arquivo contido no path
##
sub getFileName
{
	my $path	= shift;
	return basename($path);
}

##
# public static getIniSections
#
# param $iniFilePath	path do arquivo de configurações .ini
# retun					sections disponíveis no arquivo
##
sub getIniSections
{
	my $iniFilePath	= shift;
	
	# carrega o arquivo de configuração
	my $configIniFiles	= Config::IniFiles->new( -file => $iniFilePath);
	
	# lança exceção caso o arquivo de configuração não tenha sido passado como parâmetro
	throw Util::Exception(100, $iniFilePath) if(not defined $configIniFiles);
	
	my @sections	= $configIniFiles->Sections();
	
	return \@sections;
}

##
# public static readIniFileBlock
#
# param $iniFilePath
# param $section
# param $minKeys
##
sub readIniFileSection
{
	my $iniFilePath	= shift;
	my $section		= shift;
	my $minKeys		= shift;
	
	$minKeys	= [] if(not defined $minKeys);
	
	# carrega o arquivo de configuração
	my $configIniFiles	= Config::IniFiles->new( -file => $iniFilePath);
	
	# lança exceção caso o arquivo de configuração não tenha sido passado como parâmetro
	throw Util::Exception(100, $iniFilePath) if(not defined $configIniFiles);
	
	# lança exceção caso a seção não exista no arquivo de configuração
	throw Util::Exception(101, "$iniFilePath section $section") if(!$configIniFiles->SectionExists($section));
	
	my %hashParameters	= ();
	
	# para cada parâmetro (atributo) da seção
	foreach my $parameter ($configIniFiles->Parameters($section))
	{
		# obtém o valor do parâmetro da seção
		my $value	= $configIniFiles->val($section, $parameter);
		
		if(!($parameter	=~ /^regexp/) && !($parameter	=~ /^mask/))
		{
			if( $value	=~ /,/)
			{
				my @params	= split(",", $value);
				$value		= [];
				
				foreach my $param (@params)
				{
					$param	= trim($param);
					
					if(($param =~ /\-/) && !($param =~ /[^\d\-]/) && !($param =~ /^\-/))
					{
						my @aux	= split("-",$param);
						
						for($aux[0] .. $aux[1])
						{
							push @{$value}, $_;
						}
					}
					else
					{
						push @{$value}, $param;
					}
				} 
			}
			elsif(($value =~ /\-/) && !($value =~ /[^\d\-]/) && !($value =~ /^\-/))
			{
				my @aux	= split("-",$value);
				
				$value	= [];
						
				for($aux[0] .. $aux[1])
				{
					push @{$value}, $_;
				}
			}
		}
		
		$hashParameters{$parameter}	= trim($value);
	}
	
	# verifica se hash contém os campos mínimos passados como parâmetros
	foreach my $key (@{$minKeys})
	{
		throw Util::Exception(103, "$key not found in $section")
			if((not exists $hashParameters{$key})||(not defined $hashParameters{$key}));
	}
	
	return \%hashParameters;
}

##
# public static unixTime
##
sub unixTime
{
	my $year	= shift;
	my $month	= shift;
	my $mday	= shift;
	my $hour	= shift;
	my $minute	= shift;
	my $second	= shift;
	
	return timelocal($second, $minute, $hour, $mday, --$month, $year);
}

##
# public static timestampToString
#
# DEPRECATED
##
sub timestampToString
{
	my $unixTime	= shift;
	my $pretty		= shift;
	
	$pretty = 0 if(not defined $pretty);
	
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($unixTime);
	
	$year	+= 1900;	
	$mon	+= 1;
	
	$mon	= "0$mon"	if($mon < 10);
	$mday	= "0$mday"	if($mday < 10);
	$sec	= "0$sec"	if($sec < 10);
	$min 	= "0$min"	if($min < 10);
	$hour	= "0$hour"	if($hour < 10);
	
	if($pretty)
	{
		return "$year-$mon-$mday $hour:$min:$sec";
	}
	else
	{
		return $year.$mon.$mday."_".$hour.$min.$sec;
	}
}

##
# public static timestampFormattedString
#
# Retorna string formatada do timestamp.
#
# param $unixTime	unix timestamp
# param $template	template do output, de acordo com a documentação do module Date::Format
# return	string do timestamp formatada de acordo com o template
##
sub timestampFormattedString
{
	my $unixTime	= shift;
	my $template	= shift;
	
	$template	= "\%Y-\%m-\%d \%H:\%M:\%S" if(not defined $template);
	
	return time2str($template,$unixTime);
}

##
# public static trim
##
sub trim
{
	my $string	= shift;
	$string	=~ s/^[ ]+//;
	$string	=~ s/[ ]+$//;
	
	return $string;
}

##
# public static changeSubstr
##
sub changeSubstrWithRegex
{
	my $string		= shift;
	my $fromRegex	= shift;
	my $toRegex		= shift;
	my $global		= shift;
	
	if($global)
	{
		$string	=~ s/$fromRegex/$toRegex/g;
	}
	else
	{
		$string =~ s/$fromRegex/$toRegex/;
	}
	
	return $string;
}

##
# public static toMD5
##
sub toMD5
{
	my $seed	= shift;
	
	my $md5 = md5_hex($seed);
	$md5 =~ tr/a-z/A-Z/;
	
	return $md5;
}

##
# public static randomToken
##
sub token
{
	my $charsList	= "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
	my @charsArray	= split(//,$charsList);
	my $seed		= "";
	my $randMax		= 1000000;
	
	for(my $i=0; $i<20; $i++)
	{
		my $randNum 	= int(rand($randMax));
		my $randIndex	= $randNum%62;
		
		$seed .= $charsArray[$randIndex]; 
	}
	
	$seed .= time();
	
	return toMD5($seed);
}

##
# public readHiddenInput
#
# Lê input do usuário, trocando os caracteres digitados por "*"
#
# param $message	mensagem a ser apresentada para o usuário
##
sub readHiddenInput
{
	my $message	= shift;
	
	print "$message: ";
	system "stty -echo -icanon";	

	my ($a,$b);

	while (sysread STDIN, $a, 1) 
	{
		last if (ord($a) < 32);
		$b .= $a;
		syswrite STDOUT, "*", 1; # print asterisk
	}
	
	system "stty echo icanon";
	print "\n";
	
	return $b;
}

##
# public static readInput
#
# param $message	mensagem a ser impressa na tela do usuário
# return			input lido do std
##
sub readInput
{
	my $message	= shift;
	
	print "$message: ";
	
	my $input 	= <STDIN>;
	chomp ($input);
	
	return $input;
}

##
# public static padRight
#
# Retorna right padded string de tamanho padLen, utilizando a string padStr
#
# param $string
# param $padStr
# param $padLen
# return	padded string
##
sub padRight
{
	my $string	= shift;
	my $padStr	= shift;
	my $padLen	= shift;
	
	throw Util::Exception(0) if((not defined $string)||(not defined $padStr)||(not defined $padLen));
	
	while(length($string) < $padLen)
	{
		$string	.= $padStr;	
	}
	
	return substr($string,0,$padLen);
}

##
# public static padLeft
#
# Retorna left padded string de tamanho padLen, utilizando a string padStr
#
# param $string
# param $padStr
# param $padLen
# return	padded string
##
sub padLeft
{
	my $string	= shift;
	my $padStr	= shift;
	my $padLen	= shift;
	
	throw Util::Exception(0) if((not defined $string)||(not defined $padStr)||(not defined $padLen));
	
	while(length($string) < $padLen)
	{
		$string	= $padStr.$string;	
	}
	
	return substr($string,length($string)-$padLen,$padLen);
}



sub splitFileByLines
{
	my $lines	= shift;
	my $file	= shift;
	my $pattern	= shift;

	system("split -l $lines $file $pattern") == 0 or throw Util::Exception(9, $file);

}




1;
