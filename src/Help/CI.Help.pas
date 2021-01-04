unit CI.Help;

interface

uses
  System.Classes,
  System.StrUtils,
  System.SysUtils,
  Winapi.Windows;

type
  THelp = class
    constructor Create(aParam: String);
    destructor Destroy; override;
    class function New(aParam: String): THelp;
  private

  public

  end;

implementation

{ THelp }

constructor THelp.Create(aParam: String);
begin
  if ( aParam = '-script' ) or ( aParam = '/?' ) then
  begin
     WriteLN('BuilderCI - A instrucao "-script" permite criar o arquivo "Latest.txt" das pastas do projeto, '  +
             'atualizar o script com a versao atual do sistema, enviar script do sprint atual para futuro '    +
             ' versionamento e atualizar a base local com todos os scripts versionados.                          ');
     WriteLN('                                                                                                   ');
     WriteLN('BuilderCI - Para criar novo script "Latest.txt", use: "-script -make -host DIRETORIO"              ');
     WriteLN('BuilderCI - Ex.: "-script -make -host "C:\Users\Public\Documments\"                                ');
     WriteLN('                                                                                                   ');
     WriteLN('BuilderCI - Para versionar script "Latest.txt", use: "-script -version 1.0.0.0 -host DIRETORIO"    ');
     WriteLN('BuilderCI - Ex.: "-script -version 1.0.0.0 -host "C:\Users\Public\Documments\"                     ');
     WriteLN('BuilderCi - Obs.: O diretorio especificado deve ser o que contem o arquivo "Latest.txt"            ');
     WriteLN('                                                                                                   ');
     WriteLN('BuilderCI - Para enviar script para versionamento, use: "-script -send -host ARQUIVO"              ');
     WriteLN('BuilderCI - Ex.: "-script -send -host "C:\Users\Public\Documments\Script.txt"                      ');
     WriteLN('                                                                                                   ');
     WriteLN('BuilderCI - Para atualizar os scripts locais, use: "-script -update -host DIRETORIO"               ');
     WriteLN('BuilderCI - Ex.: "-script -send -host "C:\Users\Public\Documments\"                                ');
     WriteLN('BuilderCI - Obs.: Caso seja a primeira atualizacao, use "-script -update -all -host DIRETORIO"     ');
     WriteLN('BuilderCI - Obs.: A instrucao "update" deve ser rodada apenas na pasta RAIZ dos scripts.           ');
  end;
end;

destructor THelp.Destroy;
begin

  inherited;
end;

class function THelp.New(aParam: String): THelp;
begin
  Result := Self.Create(aParam);
end;

end.
