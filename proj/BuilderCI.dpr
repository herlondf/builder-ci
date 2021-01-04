program BuilderCI;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  CI.Help in '..\src\Help\CI.Help.pas',
  CI.Changelog in '..\src\changelog\CI.Changelog.pas',
  BuilderCI.DAO.Script in '..\src\Script\DAO\BuilderCI.DAO.Script.pas',
  CI.ProjectVersion in '..\src\Project\CI.ProjectVersion.pas',
  uClasseFTP in '..\src\Utils\uClasseFTP.pas',
  uThreadFTP in '..\src\Utils\uThreadFTP.pas',
  BuilderCI.DAO.Script.Interfaces in '..\src\Script\DAO\BuilderCI.DAO.Script.Interfaces.pas';

var
  FResult: String;

begin
  try
    if ParamStr(1) = '/?' then
      THelp.New('/?')
    else
    if ( ParamStr(1) = '-script' ) or ( FileExists( ParamStr(1) ) )  then
      TScript.New
    else
    if ParamStr(1) = '-changelog' then
      TChangelog.New
    else
    if ParamStr(1) = '-project'   then
      TProjectVersion.New
    else
    begin
      WriteLN('BuilderCI - Comando desconhecido: ' + ParamStr(3)       );
      WriteLN('BuilderCI - Para ajuda, digite "ci_viggo.exe /?".      ');
      ReadLN(FResult);
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ReadLN(FResult);
    end;
  end;
end.
