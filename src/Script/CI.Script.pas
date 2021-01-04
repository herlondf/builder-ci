unit CI.Script;

interface

uses
  uClasseFTP,
  System.Classes,
  System.StrUtils,
  System.SysUtils,
  Winapi.Windows,
  CI.Help;

type
  TScript = class
    constructor Create;
    destructor Destroy; override;
    class function New: TScript;
  private
    FFTP       : TFTP;
    FDeveloper : String;
    FTicket    : String;
    FSprint    : String;

    function Validate: Boolean;
  public
    procedure Make;
    procedure Version;
    procedure Send(aDirect: Boolean = False);
  end;

implementation

const
  FHost = '64.31.51.19';
  FUser = 'viggo_script';
  FPass = 'AL7Bo![/G%S$iU(3*48%7R-8*)h[?K>';
  FPort = '47286';

{ TVersion }

constructor TScript.Create;
begin
  if ( ParamStr(2) = '-make'    ) and Validate then
    Make
  else
  if ( ParamStr(2) = '-version' ) and Validate then
    Version
  else
  if ( ParamStr(2) = '-send'    ) and Validate then
    Send
  else
  if FileExists( ParamStr(1) ) and ( ExtractFileExt( ParamStr(1) ) = '.txt' ) then
    Send(True);
end;

destructor TScript.Destroy;
begin

  inherited;
end;

class function TScript.New: TScript;
begin
  Result := Self.Create;
end;

function TScript.Validate: Boolean;
begin
  if ParamStr(2) = '/?' then
  begin
    THelp.New('-script');
    Result := False;
    Exit;
  end;

  if ParamStr(2) = '-make' then
  begin
    //   1       2    3                 4
    //-script -make -host "C:\_Atualizador\_Scripts\VIS\"

    if  ( ParamStR(3) <> '-host' ) then
    begin
      WriteLN('                                                                                           ');
      WriteLN('BuilderCI - Parametro <' + ParamStr(3) + '> desconhecido para a instrucao "-script -make"  ');
      WriteLN('BuilderCI - Obrigatorio o parametro "-host".                                               ');
      WriteLN('BuilderCI - Para mais informacoes, digite: -script /?                                      ');
      WriteLN('                                                                                           ');
      Result := False;
    end
    else
    if not DirectoryExists( ParamStr( 4 ) ) then
    begin
      WriteLN('                                                                                ');
      WriteLN('BuilderCI - Diretorio <' + ParamStr(4) + '> nao esta acessivel ou nao existe.   ');
      WriteLN('BuilderCI - Verifique se esta disponivel e existe, em seguida tennte novamente. ');
      WriteLN('BuilderCI - Para mais informacoes, digite: -script /?                           ');
      WriteLN('                                                                                ');
      Result := False;
    end
    else
    if FileExists( ParamStr( 4 ) + '\Latest.txt' ) then
    begin
      WriteLN('                                                                     ');
      WriteLN('BuilderCI - Arquivo <' + ParamStr(4) + '\Latest.txt' + '> ja existe. ');
      WriteLN('BuilderCI - Para mais informacoes, digite: -script /?                ');
      WriteLN('                                                                     ');
      Result := False;
    end
    else
      Result := True;
  end
  else
  if ParamStr(2) = '-version' then
  begin
    //   1        2        3      4                    5
    //-script -version 10.0.0.1 -host "C:\_Atualizador\_Scripts\VIS\"

    if ParamStr(3) = '' then
    begin
      WriteLN('                                                                                          ');
      WriteLN('BuilderCI - Parametro <' + ParamStr(3) + '> desconhecido para instrucao -script -version. ');
      WriteLN('BuilderCI - Obrigatorio informar a versao.                                                ');
      WriteLN('BuilderCI - Para mais informacoes, digite: -script /?                                     ');
      WriteLN('                                                                                          ');
      Result := False;
    end
    else
    if  ( ParamStR(4) <> '-host' ) then
    begin
      WriteLN('                                                                                             ');
      WriteLN('BuilderCI - Parametro <' + ParamStr(4) + '> desconhecido para a instrucao "-script -version" ');
      WriteLN('BuilderCI - Obrigatorio o parametro "-host".                                                 ');
      WriteLN('BuilderCI - Para mais informacoes, digite: -script /?                                        ');
      WriteLN('                                                                                             ');
      Result := False;
    end
    else
    if not DirectoryExists( ParamStr( 5 ) ) then
    begin
      WriteLN('                                                                                ');
      WriteLN('BuilderCI - Diretorio <' + ParamStr(5) + '> nao esta acessivel ou nao existe.   ');
      WriteLN('BuilderCI - Verifique se esta disponivel e existe, em seguida tennte novamente. ');
      WriteLN('BuilderCI - Para mais informacoes, digite: -script /?                           ');
      WriteLN('                                                                                ');
      Result := False;
    end
    else
    if not FileExists ( ParamStr(5) + '\Latest.txt' ) then
    begin
      WriteLN('                                                                       ');
      WriteLN('BuilderCI - Arquivo <' + ParamStr(5) + '\Latest.txt' + '> inexistente. ');
      WriteLN('BuilderCI - Para mais informacoes, digite: -script /?                  ');
      WriteLN('                                                                       ');
      Result := False;
    end
    else
      Result := True;
  end
  else
  if ParamStr(2) = '-send' then
  begin
    //   1      2     3                   4
    //-script -send -host "C:\_Atualizador\_Scripts\VIS\Script.txt"

    if ( ParamStr(3) = '-host' ) then
    begin
      if  ( not FileExists( ParamStr(4) ) or ( ExtractFileExt( ParamStr(4) ) <> '.txt' ) ) then
      begin
        WriteLN('                                                                                        ');
        WriteLN('BuilderCI - Arquivo <' + ParamStr(4) + '> inexistente ou com extensao diferente de txt. ');
        WriteLN('BuilderCI - Para mais informacoes, digite: -script /?                                   ');
        WriteLN('                                                                                        ');
        Result := False;
      end
      else
        Result := True;
    end
    else
    begin
      WriteLN('                                                                                           ');
      WriteLN(' BuilderCI - Parametro <' + ParamStr(3) + '> desconhecido para a instrucao "-script -send" ');
      WriteLN(' BuilderCI - Obrigatorio o parametro "-host"                                               ');
      WriteLN(' BuilderCI - Para mais informacoes, digite: -scriptsend /?                                 ');
      WriteLN('                                                                                           ');

      Result := False;
    end;
  end;
end;

procedure TScript.Make;
var
  FArqFinal : TextFile;
begin
  AssignFile( FArqFinal , ParamStr(4) +  '\Latest.txt' );
  Rewrite   ( FArqFinal );
  CloseFile ( FArqFinal );
end;

procedure TScript.Send(aDirect: Boolean = False);
label
  Envio;
label
  ErroEnvio;
label
  Developer;
label
  Ticket;
label
  Sprint;
var
  I               : Integer;
  arqScript       : TextFile;
  arqScriptFinal  : TextFile;
  Linha           : String;
  Lista           : TStringList;
  FResult         : String;
  FOutConnectFTP  : String;
  FFileParam      : String;
begin
  if aDirect then
    FFileParam := ParamStr(1)
  else
    FFileParam := ParamStr(3);

  FFTP := TFTP.Create;
  FFTP.Config(
    FHost,
    FUser,
    FPass,
    StrToInt(FPort),
    True,
    False,
    True
  );

  FFTP.Connect('\', FOutConnectFTP);

  Lista := TStringList.Create;

  AssignFile ( arqScript, FFileParam );
  Reset ( arqScript );

  while not Eof ( arqScript ) do
  begin
    ReadLn( arqScript, Linha );
    Lista.Add( Linha );
  end;

  CloseFile ( arqScript );

  Developer:
  Write (' BuilderCI - Desenvolvedor: ');
  ReadLN( FDeveloper                   );

  if FDeveloper = '' then
    goto Developer;

  Sprint:
  Write (' BuilderCI - Sprint.......: ');
  ReadLN(FSprint);

  if FSprint = '' then
    goto Sprint;

  Ticket:
  Write (' BuilderCI - Ticket.......: ');
  ReadLN( FTicket                      );

  if FTicket = '' then
    goto Ticket;

  if RenameFile( FFileParam , ChangeFileExt( FFileParam, '.tmp' ) ) then
  begin

    AssignFile ( arqScriptFinal, ExtractFilePath( FFileParam ) + FTicket + '.txt' );
    Rewrite( arqScriptFinal );

    WriteLN(arqScriptFinal, '/* --------------------------- ' + FTicket + ' ---------------------------                                 ');
    WriteLN(arqScriptFinal, ' Desenvolvedor: ' + FDeveloper                                                                              );
    WriteLN(arqScriptFinal, ' Sprint.......: ' + FSprint                                                                                 );
    WriteLN(arqScriptFinal, ' Demanda......: ' + FTicket                                                                                 );
    WriteLN(arqScriptFinal, ' URL..........: https://viggosistemas.acelerato.com/tickets/' + FTicket                                     );
    WriteLN(arqScriptFinal, '-----------------------------' + StringOfChar('-', Length( FTicket ) ) + '----------------------------- */ ');
    WriteLN(arqScriptFinal, '                                                                                                           ');

    for I := 0 to Pred( Lista.Count ) do
      Writeln( arqScriptFinal, Lista.Strings[I] );

    WriteLN(arqScriptFinal, '/* -------------------------- ' + FTicket + ' --------------------------- */ ');
    WriteLN(arqScriptFinal, '                                                                             ');

    CloseFile( arqScriptFinal );

    Lista.Free;

    WriteLN(' BuilderCI - Enviando o arquivo...');

    FFTP.MakeDir(FSprint);

    Envio:

    if FFTP.SendFile(  ExtractFilePath( FFileParam ) + FTicket + '.txt', FTicket + '.txt' ) then
    begin
      WriteLN(' BuilderCI - Arquivo enviado com sucesso!');
      DeleteFile( PWideChar( ChangeFileExt( FFileParam, '.tmp' ) ) );
    end
    else
    begin
      ErroEnvio:

      WriteLN(' BuilderCI - Ops... Ocorreu algum erro ao enviar o arquivo para o servidor. ');
      Write  (' BuilderCI - Deseja tentar enviar novamente(S/N)? '                          );
      ReadLN (FResult);

      if ( UpperCase( FResult ) <>  'S' ) and ( UpperCase( FResult ) <> 'N' ) then
      begin
        WriteLN(' BuilderCI - Nao entendi sua resposta. Vamos tentar novamente. ');
        goto ErroEnvio;
      end
      else
      if FResult = 'S' then
        goto Envio
      else
      begin
        DeleteFile( PWideChar( ExtractFilePath( FFileParam ) + FTicket + '.txt' ) );
        RenameFile( ChangeFileExt( FFileParam, '.tmp' )  , ChangeFileExt( FFileParam, '.txt' ) );
        Exit;
      end;
    end;
  end
  else
  begin
    WriteLN('                                                                     ');
    WriteLN(' BuilderCI - Nao foi possivel renomear o arquivo.                    ');
    WriteLN(' BuilderCI - Verifique se o mesmo nao esta aberto e tente novamente. ');
    WriteLN('                                                                     ');
    Exit;
  end;

  FFTP.Disconnect(FOutConnectFTP);
  FFTP.Free;

  WriteLN(' BuilderCI - Bom trabalho! Ate a proxima ' + FDeveloper + '...');
  ReadLN(FResult);
end;

procedure TScript.Version;
var
  FLista          : TStringList;
  I               : Integer;
  arqLatest       : TextFile;
  arqLatestFinal  : TextFile;
  Linha           : String;
begin
  FLista := TStringList.Create;

  AssignFile ( arqLatest, ParamStr(5) + '\Latest.txt' );
  Reset ( ArqLatest );

  while not Eof ( ArqLatest ) do
  begin
    ReadLn( ArqLatest, Linha );
    FLista.Add( Linha );
  end;

  CloseFile ( ArqLatest );

  if RenameFile( ParamStr(5) + '\Latest.txt', ChangeFileExt( ParamStr(5) + '\Latest.txt', '.tmp' ) ) then
  begin
    AssignFile( arqLatestFinal, ExtractFilePath( ParamStr(5) + '\Latest.txt' ) +  ParamStr(3) + '.txt' );
    Rewrite( arqLatestFinal );

    Writeln( arqLatestFinal, 'VERSAOINICIAL:' + ParamStr(3)                  );
    Writeln( arqLatestFinal, 'SCRIPT-SQL'                                    );
    Writeln( arqLatestFinal, '{'                                             );

    for I := 0 to Pred( FLista.Count ) do
      Writeln( arqLatestFinal, FLista.Strings[I] );

    Writeln( arqLatestFinal, '}'                                             );
    Writeln( arqLatestFinal, 'COMENTARIO'                                    );
    Writeln( arqLatestFinal, '{'                                             );
    Writeln( arqLatestFinal, 'CRMVERSAO - ATUALIZACAO VERSAO ' + ParamStr(3) );
    Writeln( arqLatestFinal, '}'                                             );
    Writeln( arqLatestFinal, 'VERSAOFINAL:' + ParamStr(3)                    );

    CloseFile( arqLatestFinal );
  end;

  DeleteFile( PWideChar( ExtractFilePath( ParamStr(5) + '\Latest.txt') + 'Latest.tmp' ) );

  FLista.Free;
end;

end.
