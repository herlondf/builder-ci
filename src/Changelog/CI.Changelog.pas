unit CI.Changelog;

interface

uses
  System.Classes,
  System.StrUtils,
  System.SysUtils,
  Winapi.Windows;

type
  TChangelog = class
    constructor Create;
    destructor Destroy; override;
    class function New: TChangelog;
  private
    function  ParamsValidate: Boolean;

    procedure RunChangelogMake;
    procedure RunChangelogVersion;
  end;

implementation

{ TChangelog }

//    1          2       3       4                 5
//-changelog -version 10.0.0.1 -host "C:\_Atualizador\_Scripts\VIS\"

//    1        2      3             4
//-changelog -make -host "C:\_Atualizador\_Scripts\VIS\"

constructor TChangelog.Create;
begin
  if ParamsValidate then
  begin
    if ParamStr(2) = '-version' then
      RunChangelogVersion
    else
    if ParamStr(2) = '-make' then
      RunChangelogMake;
  end;
end;

destructor TChangelog.Destroy;
begin

  inherited;
end;

class function TChangelog.New: TChangelog;
begin
  Result := Self.Create;
end;

procedure TChangelog.RunChangelogVersion;
var
  I               : Integer;
  arqLatest       : TextFile;
  arqLatestFinal  : TextFile;
  Linha           : String;
  Lista           : TStringList;
begin
  Lista := TStringList.Create;

  AssignFile ( arqLatest, ParamStr(5) + '\Latest.txt' );
  Reset ( ArqLatest );

  while not Eof ( ArqLatest ) do
  begin
    ReadLn( ArqLatest, Linha );
    Lista.Add( Linha );
  end;

  CloseFile ( ArqLatest );

  if RenameFile( ParamStr(5) + '\Latest.txt', ChangeFileExt( ParamStr(5) + '\Latest.txt', '.tmp' ) ) then
  begin
    AssignFile( arqLatestFinal, ExtractFilePath( ParamStr(5) + '\Latest.txt' ) +  ParamStr(3) + '.txt' );
    Rewrite( arqLatestFinal );

    Writeln( arqLatestFinal, '*******************************'               );
    Writeln( arqLatestFinal, 'Versao: ' + ParamStr(3)                        );
    Writeln( arqLatestFinal, '*******************************'               );
    Writeln( arqLatestFinal, ''                                              );

    for I := 0 to Pred( Lista.Count ) do
      Writeln( arqLatestFinal, Lista.Strings[I] );

    CloseFile( arqLatestFinal );

    Lista.Free;
  end;

  DeleteFile( PWideChar( ExtractFilePath( ParamStr(5) + '\Latest.txt') + 'Latest.tmp' ) );
end;

procedure TChangelog.RunChangelogMake;
var
  FArq: TextFile;
begin
  try
    AssignFile( FArq, ParamStr(4) +  '\Latest.txt' );
    Rewrite   ( FArq );
    CloseFile ( FArq );
  except
    On E: Exception do
    begin
      WriteLN(' BuilderCI - Nao foi possivel criar arquivo "Latest.txt" ');
      WriteLN( E.Message );
      Exit;
    end;
  end;
end;

function TChangelog.ParamsValidate: Boolean;
begin
  if ParamStr(2) = '/?' then
  begin
    WriteLN('                                                                                       ');
    WriteLN(' BuilderCI - O helper do changelog esta em construcao.                                 ');
    WriteLN('                                                                                       ');
    Result := False;
    Exit;
  end;

  if ParamStr(2) = '-version' then
  begin
    if  ( ParamStR(3) = '' ) then
    begin
      WriteLN('                                                                                      ');
      WriteLN(' BuilderCI - Valor <' + ParamStr(3) + '> desconhecido para a instrucao "-project"     ');
      WriteLN(' BuilderCI - Obrigatorio o valor da versao.                                           ');
      WriteLN(' BuilderCI - Para mais informacoes, digite: -changelog /?                             ');
      WriteLN('                                                                                      ');
      Result := False;
    end
    else
    if ParamStr(4) <> '-host' then
    begin
      WriteLN('                                                                                      ');
      WriteLN(' BuilderCI - Valor <' + ParamStr(4) + '> desconhecido para a instrucao "-project"     ');
      WriteLN(' BuilderCI - Obrigatorio o parametro "-host" para localizadao do projeto.             ');
      WriteLN(' BuilderCI - Para mais informacoes, digite: -changelog /?                             ');
      WriteLN('                                                                                      ');
      Result := False;
    end
    else
    if ( ParamStr(5) = '' ) or ( not FileExists( ParamStr(5) + '\Latest.txt' ) ) then
    begin
      WriteLN('                                                                                      ');
      WriteLN(' BuilderCI - Valor <' + ParamStr(5) + '> desconhecido para a instrucao "-project"     ');
      WriteLN(' BuilderCI - Obrigatorio o valor e a existencia do projeto.                           ');
      WriteLN(' BuilderCI - Para mais informacoes, digite: -changelog /?                             ');
      WriteLN('                                                                                      ');
      Result := False;
    end
    else
      Result := True;
  end
  else
  if ParamStr(2) = '-make' then
  begin
    if ParamStr(3) <> '-host' then
    begin
      WriteLN('                                                                                      ');
      WriteLN(' BuilderCI - Valor <' + ParamStr(4) + '> desconhecido para a instrucao "-project"     ');
      WriteLN(' BuilderCI - Obrigatorio o parametro "-host" para localizadao do projeto.             ');
      WriteLN(' BuilderCI - Para mais informacoes, digite: -changelog /?                             ');
      WriteLN('                                                                                      ');
      Result := False;
    end
    else
    if ( ParamStr(4) = '' ) then
    begin
      WriteLN('                                                                                      ');
      WriteLN(' BuilderCI - Valor <' + ParamStr(5) + '> desconhecido para a instrucao "-project"     ');
      WriteLN(' BuilderCI - Obrigatorio o valor para criar o arquivo.                                ');
      WriteLN(' BuilderCI - Para mais informacoes, digite: -changelog /?                             ');
      WriteLN('                                                                                      ');
      Result := False;
    end
    else
      Result := True;
  end
  else
  begin
    WriteLN('                                                                                        ');
    WriteLN(' BuilderCI - Parametro <' + ParamStr(2) + '> desconhecido para a instrucao "-changelog" ');
    WriteLN(' BuilderCI - Obrigatorio o parametro "-version" ou "-make".                             ');
    WriteLN(' BuilderCI - Para mais informacoes, digite: -changelog /?                               ');
    WriteLN('                                                                                        ');
    Result := False;
  end;
end;

end.
