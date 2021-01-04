unit CI.ScriptSendFTP;

interface

uses
  uClasseFTP,
  System.Classes,
  System.StrUtils,
  System.SysUtils,
  Winapi.Windows;

type
  TScriptSendFTP = class
    constructor Create;
    destructor Destroy; override;
    class function New: TScriptSendFTP;
  private
    FFTP: TFTP;
    FDeveloper : String;
    FTicket    : String;
    FSprint    : String;

    function  ParamsValidate: Boolean;

    procedure RunSendScript(aParam: Boolean = False);
  end;

implementation

const
  FHost = '64.31.51.19';
  FUser = 'viggo_script';
  FPass = 'AL7Bo![/G%S$iU(3*48%7R-8*)h[?K>';
  FPort = '47286';

{ TScriptSendFTP }

//    1         2          3
//-scriptsend -host "D:\Script.sql"

constructor TScriptSendFTP.Create;
begin
  if FileExists( ParamStr(1) ) and ( ExtractFileExt( ParamStr(1) ) = '.txt' ) then
  begin
    RunSendScript(True);
    Exit;
  end
  else
  begin
    WriteLN(' BuilderCI - Arquivo inexistente ou extensao diferente de txt ');
    Exit;
  end;

  if ParamsValidate then
  begin
    RunSendScript;
  end;
end;

destructor TScriptSendFTP.Destroy;
begin

  inherited;
end;

class function TScriptSendFTP.New: TScriptSendFTP;
begin
  Result := Self.Create;
end;

function TScriptSendFTP.ParamsValidate: Boolean;
label
  Developer;
label
  Ticket;
begin
  if ParamStr(2) = '/?' then
  begin
    WriteLN('                                                                                       ');
    WriteLN(' BuilderCI - O helper do scriptsend esta em construcao.                                ');
    WriteLN('                                                                                       ');
    Result := False;
    Exit;
  end;

  if ( ParamStr(2) = '-host' ) then
  begin
    if  ( FileExists( ParamStr(3) ) and ( ExtractFileExt( ParamStr(3) ) = '.txt' ) ) then
    begin
      Result := True;
    end
    else
    begin
      WriteLN('                                                                                         ');
      WriteLN(' BuilderCI - Parametro <' + ParamStr(3) + '> desconhecido para a instrucao "-host"       ');
      WriteLN(' BuilderCI - Obrigatorio informar o caminho completo do arquivo                          ');
      WriteLN(' BuilderCI - Para mais informacoes, digite: -scriptsend /?                               ');
      WriteLN('                                                                                         ');

      Result := False;
    end;
  end
  else
  begin
    WriteLN('                                                                                         ');
    WriteLN(' BuilderCI - Parametro <' + ParamStr(2) + '> desconhecido para a instrucao "-scriptsend" ');
    WriteLN(' BuilderCI - Obrigatorio o parametro "-host"                                             ');
    WriteLN(' BuilderCI - Para mais informacoes, digite: -scriptsend /?                               ');
    WriteLN('                                                                                        ');

    Result := False;
  end;
end;

procedure TScriptSendFTP.RunSendScript(aParam: Boolean = False);
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
  if aParam then
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

end.
