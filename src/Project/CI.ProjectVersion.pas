unit CI.ProjectVersion;

interface

uses
  Xml.xmldom,
  Xml.XMLIntf,
  Xml.XMLDoc,
  Winapi.ActiveX,
  System.Classes,
  System.StrUtils,
  System.SysUtils;

type
  TProjectVersion = class
    constructor Create;
    destructor Destroy;
    class function New: TProjectVersion;
  private
    FLista       : TStringList;
    FXMLDocument : IXMLDocument;
    FVersion     : String;

    function  ParamsValidate: Boolean;
    procedure AdjustVersion;
    procedure AndaNode(aNode: IXMLNode; aTextSearch: String = '');
    procedure RunProject;
  end;

implementation

{ TProjectVersion }

//    1         2        3      4          5
// -project -version 10.0.0.1 -host "C:\Projeto.dproj"

//    1      2
// -project /?

constructor TProjectVersion.Create;
begin
  if ParamsValidate then
    RunProject;
end;

destructor TProjectVersion.Destroy;
begin

end;

class function TProjectVersion.New: TProjectVersion;
begin
  Result := Self.Create;
end;

procedure TProjectVersion.RunProject;
begin
  CoInitialize(nil);
  FXMLDocument := TXMLDocument.Create(nil);

  FLista           := TStringList.Create;
  FLista.Delimiter := ';';

  AdjustVersion;

  FXMLDocument.LoadFromFile( ParamStr(5) );
  FXMLDocument.Active := True;
  AndaNode( FXMLDocument.ChildNodes.First, 'VerInfo_Keys' );
  FXMLDocument.SaveToFile( ParamStr(5) );

  FLista.Free;
  CoUninitialize;
end;

procedure TProjectVersion.AdjustVersion;
var
  FListaVersion: TStringList;
  I: Integer;
begin
  FVersion      := '';
  FListaVersion := TStringList.Create;
  FListaVersion.Delimiter := '.';

  FListaVersion.DelimitedText := ParamStr(3);

  for I := 0 to Pred( FListaVersion.Count ) do
  begin
    if I = Pred( FListaVersion.Count ) then
      FVersion := FVersion + IntToStr( StrToInt( FListaVersion.Strings[I] ) )
    else
      FVersion := FVersion + IntToStr( StrToInt( FListaVersion.Strings[I] ) ) + '.';
  end;

  FListaVersion.Free;
end;

procedure TProjectVersion.AndaNode(aNode: IXMLNode; aTextSearch: String);
var
  I, J        : Integer;
  FNodePai    : IXMLNode;
  FNodeValue  : String;
begin
  for I := 0 to Pred( aNode.ChildNodes.Count ) do
  begin
    FNodePai := aNode.ChildNodes.Get(I);

    if FNodePai.NodeName = aTextSearch then
    begin
      FLista.DelimitedText := FNodePai.NodeValue;

      for J := 0 to Pred( FLista.Count ) do
      begin
        if Copy( AnsiUpperCase( FLista.Strings[J] ), 0, 11 ) = 'FILEVERSION' then
          FNodeValue := FNodeValue + 'FileVersion=' + FVersion + ';'
        else
        if Copy( AnsiUpperCase( FLista.Strings[J] ), 0, 14 ) = 'PRODUCTVERSION' then
          FNodeValue := FNodeValue + 'ProductVersion=' + FVersion + ';'
        else
          FNodeValue := FNodeValue + FLista.Strings[J] + ';';
      end;

      FNodePai.Text := FNodeValue;
      FNodeValue    := '';

    end;

    if FNodePai.ChildNodes.Count > 1 then
      AndaNode( FNodePai, aTextSearch );
  end;
end;

function TProjectVersion.ParamsValidate: Boolean;
begin
  if ParamStr(2) = '/?' then
  begin
    WriteLN(' BuildCI - O helper esta em construcao. ');
    Result := False;
    Exit;
  end;

  if ParamStr(2) <> '-version' then
  begin
    WriteLN(' BuildCI - Parametro <' + ParamStr(2) + '> desconhecido para a instrucao "-project" ');
    WriteLN(' BuildCI - Obrigatorio o parametro "-version".                                      ');
    WriteLN(' BuildCI - Para mais informacoes, digite: -project /?                               ');
    Result := False;
  end
  else
  if ParamStr(3) = '' then
  begin
    WriteLN(' BuildCI - Valor <' + ParamStr(3) + '> desconhecido para a instrucao "-project"     ');
    WriteLN(' BuildCI - Obrigatorio o valor da versao.                                           ');
    WriteLN(' BuildCI - Para mais informacoes, digite: -project /?                               ');
    Result := False;
  end
  else
  if ParamStr(4) <> '-host' then
  begin
    WriteLN(' BuildCI - Valor <' + ParamStr(4) + '> desconhecido para a instrucao "-project"     ');
    WriteLN(' BuildCI - Obrigatorio o parametro "-host" para localizadao do projeto.             ');
    WriteLN(' BuildCI - Para mais informacoes, digite: -project /?                               ');
    Result := False;
  end
  else
  if ( ParamStr(5) = '' ) or ( not FileExists( ParamStr(5) ) ) then
  begin
    WriteLN(' BuildCI - Valor <' + ParamStr(5) + '> desconhecido para a instrucao "-project"     ');
    WriteLN(' BuildCI - Obrigatorio o valor e a existencia do projeto.                           ');
    WriteLN(' BuildCI - Para mais informacoes, digite: -project /?                               ');
    Result := False;
  end
  else
    Result := True;
end;

end.
