unit CI.ScriptVersion;

interface

uses
  System.Classes,
  System.StrUtils,
  System.SysUtils,
  Winapi.Windows;

type
  TScriptVersion = class
    constructor Create;
    destructor Destroy; override;
    class function New: TScriptVersion;
  private

  public

  end;

implementation

{ TVersion }

constructor TScriptVersion.Create;
var
  I               : Integer;
  arqLatest       : TextFile;
  arqLatestFinal  : TextFile;
  Linha           : String;
  Lista           : TStringList;
begin
  if ParamStr(2) = '-make' then
  begin

    //**********************************************************************
    //-script -make -host "C:\_Atualizador\_Scripts\VIS\"
    //   1       2    3                 4
    //**********************************************************************

    if  ( ParamStR(3) <> '-host' ) then
    begin
      WriteLN(' ci_viggo(script) - Comando desconhecido: ' + ParamStr(3)       );
      WriteLN(' ci_viggo(script) - Para ajuda, digite "ci_viggo.exe /?"       ');
      Exit;
    end
    else
    if not DirectoryExists( ParamStr( 4 ) ) then
    begin
      WriteLN(' ci_viggo(script) - Diretorio invalido para instrucao "-make". ');
      WriteLN(' ci_viggo(script) - Para ajuda, digite "ci_viggo.exe /?"       ');
      Exit;
    end;

    if not FileExists( ParaMStr(4) + '\Latest.txt' ) then
    begin
      try
        AssignFile( arqLatestFinal, ParamStr(4) +  '\Latest.txt' );
        Rewrite   ( arqLatestFinal );
        CloseFile ( arqLatestFinal );
      except
        On E: Exception do
        begin
          WriteLN(' ci_viggo(script) - Nao foi possivel criar arquivo "Latest.txt" ');
          WriteLN( E.Message );
          Exit;
        end;
      end;
    end
    else
    begin
      WriteLN(' ci_viggo(script) - Ja existe arquivo Latest.txt ');
      Exit;
    end;
  end
  else
  if ParamStr(2) = '-version' then
  begin

    //**********************************************************************
    //-script -version 10.0.0.1 -host "C:\_Atualizador\_Scripts\VIS\"
    //   1        2        3      4                      5
    //**********************************************************************

    if ParamStr(3) = '' then
    begin
      WriteLN(' ci_viggo(script) - Nao foi identificado versao na instrucao. ');
      WriteLN(' ci_viggo(script) - Para ajuda, digite "ci_viggo.exe /?"      ');
      Exit;
    end
    else
    if  ( ParamStR(4) <> '-host' ) then
    begin
      WriteLN(' ci_viggo(script) - Comando desconhecido: ' + ParamStr(3)       );
      WriteLN(' ci_viggo(script) - Para ajuda, digite "ci_viggo.exe /?"       ');
      Exit;
    end
    else
    if not FileExists ( ParamStr(5) + '\Latest.txt' ) then
    begin
      WriteLN(' ci_viggo(script) - Diretorio invalido para instrucao "-version". ');
      WriteLN(' ci_viggo(script) - Para ajuda, digite "ci_viggo.exe /?"          ');
      Exit;
    end;

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

      Writeln( arqLatestFinal, 'VERSAOINICIAL:' + ParamStr(3)                  );
      Writeln( arqLatestFinal, 'SCRIPT-SQL'                                    );
      Writeln( arqLatestFinal, '{'                                             );

      for I := 0 to Pred( Lista.Count ) do
        Writeln( arqLatestFinal, Lista.Strings[I] );

      Writeln( arqLatestFinal, '}'                                             );
      Writeln( arqLatestFinal, 'COMENTARIO'                                    );
      Writeln( arqLatestFinal, '{'                                             );
      Writeln( arqLatestFinal, 'CRMVERSAO - ATUALIZACAO VERSAO ' + ParamStr(3) );
      Writeln( arqLatestFinal, '}'                                             );
      Writeln( arqLatestFinal, 'VERSAOFINAL:' + ParamStr(3)                    );

      CloseFile( arqLatestFinal );
    end;

    DeleteFile( PWideChar( ExtractFilePath( ParamStr(5) + '\Latest.txt') + 'Latest.tmp' ) );

    Lista.Free;
  end;
end;

destructor TScriptVersion.Destroy;
begin

  inherited;
end;

class function TScriptVersion.New: TScriptVersion;
begin
  Result := Self.Create;
end;

end.
