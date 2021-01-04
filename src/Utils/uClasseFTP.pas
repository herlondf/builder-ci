unit uClasseFTP;

interface

uses
  Vcl.ExtCtrls                ,   IdContext           ,   IdFTPServer      , IdAttachmentFile              ,
  Vcl.StdCtrls                ,   IdBaseComponent     ,   IdTCPConnection  , IdExplicitTLSClientServerBase ,
  System.Classes              ,   IdComponent         ,   IdTCPClient      , IdIOHandler                   ,
  System.SysUtils             ,   IdCustomTCPServer   ,   IdFTP            , IdIOHandlerSocket             ,
  Vcl.Forms                   ,   IdTCPServer         ,   IdGlobal         , IdIOHandlerStack              ,
  Winapi.Windows              ,   IdCmdTCPServer      ,   IdFTPCommon      , IdSSL                         ,
  Vcl.ComCtrls                ,   IdAntiFreezeBase    ,   IdSMTP           , IdIntercept                   ,
  System.Variants             ,   IdAntiFreeze        ,   IdSSLOpenSSL     , IdText                        ,
  System.Generics.Collections ,   IdFTPList           ,   IdMessage        ,
  Vcl.Dialogs                 ,   IdAllFTPListParsers ,   uThreadFTP       ;

type
  TFTP = class
  private
    FIdFTP: TIdFTP;
    FProxy: TIdFtpProxySettings;
    FNoProxy: TIdFtpProxySettings;
    FIdSSLIoHandlerSocketopenSSL : TIdSSLIOHandlerSocketOpenSSL;
    FTimer: TTimer;
    FThreadFTP : TThreadFTP;
    FProgressBar: TProgressBar;
    FTransferLabel: TLabel;
    FMemoLog: TMemo;
    FStatusBar: TStatusBar;

    procedure FtpWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
    procedure FtpWorkBegin(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Int64);
    procedure FtpWorkEnd(ASender: TObject; AWorkMode: TWorkMode);

    { Private declarations }
  public
    constructor Create();
    destructor Destroy; override;

    procedure Config(AHost, AUsername, APassword: String; APort: Integer;
              APassive, AUseProxy: Boolean; aUseTLS: Boolean = False);
    procedure ConfigProxy(AHost, AUsername, APassword: String; APort: Integer);
    procedure CreateTimer;
    procedure GetOnTimer(Snder: TObject);
    procedure baixarArquivo(const ASourceFile, ADestFile: string; const ACanOverwrite: Boolean = False;
              AResume: Boolean = False);
    procedure diretorioRaiz;

    function diretorioAtual: string;
    function MakeDir(aDirectory: string): String; overload;
    function mudarDiretorio(pDiretorio: string): String; overload;
    function FileExists(aFile: String = ''; aFilter: String = '/'): Boolean;
    function TestConnection(AFTPPath: TFileName;
             out AMessageException: String): Boolean;
    function Connect(AFTPPath: TFileName;
             out AMessageException: String): Boolean;
    function Disconnect(out AMessageException: String): Boolean;
    function SendFile(AFTPPath, AFilePath, AFileName: TFileName; out AMessageException: String): Boolean; overload;
    function SendFile(const ASourceFile: string; const ADestFile: string = ''; const AAppend: Boolean = False; const AStartPos: TIdStreamSize = -1): Boolean; overload;
    function ReceiveFile(AFTPPath, AFilePath, AFileName: TFileName;
             out AMessageException: String): Boolean;
    property TransferProgressBar : TProgressBar read FProgressBar write FProgressBar;
    property TransferLabel : TLabel read FTransferLabel write FTransferLabel;
    property MemoLog : TMemo read FMemoLog write FMemoLog;
    property StatusBar : TStatusBar read FStatusBar write FStatusBar;
    { Public declarations }
  protected

    { Protected declarations }
  end;

implementation

{ TFtp }

procedure TFtp.Config(AHost, AUsername, APassword: String; APort: Integer;
  APassive, AUseProxy: Boolean; aUseTLS: Boolean = false);
begin
  with FIdFTP do
  begin
    if aUseTLS then
    begin
      IOHandler           := FIdSSLIoHandlerSocketopenSSL;
      UseTLS              := utUseExplicitTLS;
      AUTHCmd             := tAuthTLS;
      DataPortProtection  := ftpdpsPrivate;
    end;

    Host                  := AHost;
    Port                  := APort;
    Username              := AUsername;
    Password              := APassword;
    Passive               := APassive;
    PassiveUseControlHost := APassive;

    UseMLIS               := True;
    UseHOST               := True;

    ListenTimeout         := 10000;
    ReadTimeout           := 60000;
    TransferTimeout       := 10000;
    TransferType          := ftBinary;

//    if AUseProxy then
//      ProxySettings := FProxy
//    else
//      ProxySettings := FNoProxy;
  end;
end;

procedure TFtp.ConfigProxy(AHost, AUsername, APassword: String; APort: Integer);
begin
  FProxy.Host := AHost;
  FProxy.Port := APort;
  FProxy.Username := AUsername;
  FProxy.Password := APassword;
end;

function TFtp.Connect(AFTPPath: TFileName;
  out AMessageException: String): Boolean;
begin
  try
    if FidFTP.Connected then
      FIdFTP.Disconnect;

    FIdFTP.Connect;
    if AFTPPath <> '' then
      FIdFTP.ChangeDir(AFTPPath);
    Result := FIdFTP.Connected;
  except
    on e: Exception do
    begin
      try
        if FidFTP.Connected then
          FIdFTP.Disconnect;

        FIdFTP.Connect;
        FIdFTP.ChangeDir('/');
        Result := FIdFTP.Connected;
        FIdFTP.Disconnect;
      except
        on e: Exception do
        begin
          FIdFTP.Disconnect;
          AMessageException := e.Message;
          Result := False;
        end;
      end;
    end;
  end;

end;

constructor TFtp.Create();
begin
  inherited Create();

  FIdFTP           := TIdFTP.Create(nil);
  FIdSSLIoHandlerSocketopenSSL := TIdSSLIOHandlerSocketOpenSSL.Create(nil);

  FIdFTP.OnWork      := FtpWork;
  FIdFTP.OnWorkBegin := FtpWorkBegin;
  FIdFTP.OnWorkEnd   := FtpWorkEnd;

  FProxy             := TIdFtpProxySettings.Create;
  FNoProxy           := FIdFTP.ProxySettings;

  CreateTimer;
end;

procedure TFtp.CreateTimer;
begin
  FTimer := TTimer.Create(nil);
  FTimer.Interval := 10000;
  FTimer.Enabled := False;
  FTimer.OnTimer := GetOnTimer;
end;

function TFtp.mudarDiretorio(pDiretorio: string): String;
begin
  try
    FIdFTP.ChangeDir(pDiretorio);
  except
    try
      FIdFTP.MakeDir(pDiretorio);
      Sleep(5000);
      FIdFTP.ChangeDir(pDiretorio);
    except
      on E: Exception do
      begin
        Result := E.Message;
        raise Exception.Create('Não foi possível criar o diretório');
      end;
    end;

  end;
end;

function TFtp.MakeDir(aDirectory: string): String;
var
  Lista: TStringList;
begin
  try
    Lista := TStringList.Create;

    FIdFTP.List(Lista, '', false);

    if Lista.IndexOf(aDirectory) <> - 1 then
      FIdFTP.ChangeDir(aDirectory)
    else
    begin
      try
        FIdFTP.MakeDir(aDirectory);
      finally
        FIdFTP.ChangeDir(aDirectory);
        FreeAndNil(Lista);
      end;
    end;
  except
    on E: Exception do
    begin
      Result := E.Message;
      raise Exception.Create(E.Message);
    end;
  end;
end;

destructor TFtp.Destroy;
begin
  if not FIdFTP.Connected then
  begin
    FreeAndNil(FIdSSLIoHandlerSocketopenSSL);
    FreeAndNil(FTimer);
    FreeAndNil(FIdFTP);
    FreeAndNil(FProxy);

    inherited Destroy;
  end;
end;

function TFtp.diretorioAtual: string;
begin
  Result := FIdFTP.RetrieveCurrentDir;
end;

procedure TFtp.diretorioRaiz;
begin
  if FIdFTP.Connected then
  begin
    while FIdFTP.RetrieveCurrentDir <> '/' do
    begin
      Sleep(5000);
      FIdFTP.ChangeDirUp;
    end;
  end;
end;

function TFtp.Disconnect(out AMessageException: String): Boolean;
begin
  if FIdFTP.Connected then
  begin
    try
      FIdFTP.Disconnect;
      Sleep(5000);
    except
      on e: Exception do
      begin
        AMessageException := e.Message;
        Result := False;
      end;
    end;
  end;
end;

function TFtp.FileExists(aFile: string = ''; aFilter: string = '/'): Boolean;
var
  I     : Integer;
  FList : TStringList;
begin
  FList := TStringList.Create;

  try
    FIdFTP.List(FList, '', false);
  except
    //
  end;

  for I := 0 to Pred( FList.Count ) do
  begin
    Result := UpperCase(aFile) = UpperCase( FList.Strings[I] );

    if Result then Break
  end;

  FList.Free;
end;

procedure TFtp.FtpWork(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
var
  iSizeTransfered: Integer;
begin
  iSizeTransfered        := AWorkCount div 1024;
  FTransferLabel.Caption := 'Transferido: ' + IntToStr(iSizeTransfered) + '/kb.';

  if Assigned(FProgressBar) then
    FProgressBar.Position := AWorkCount;
end;

procedure TFtp.FtpWorkBegin(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Int64);
begin
  if Assigned(FProgressBar) then
  begin
    FProgressBar.Max      := AWorkCountMax;
    FProgressBar.Position := 0;
  end;
end;

procedure TFtp.FtpWorkEnd(ASender: TObject; AWorkMode: TWorkMode);
begin
  if Assigned(FProgressBar) then
    FProgressBar.Position := 0;
end;

procedure TFtp.baixarArquivo(const ASourceFile, ADestFile: string; const ACanOverwrite: Boolean = False;
  AResume: Boolean = False);
begin
  FIdFTP.Get(ASourceFile, ADestFile, ACanOverwrite, AResume);
end;

procedure TFtp.GetOnTimer(Snder: TObject);
begin

  if FIdFTP.Connected then
    FStatusBar.Panels[1].Text := 'State: Connected'
  else if not FIdFTP.Connected then
    FStatusBar.Panels[1].Text := 'State: Discconnected';

end;

function TFtp.ReceiveFile(AFTPPath, AFilePath, AFileName: TFileName;
  out AMessageException: String): Boolean;
begin
  try
    Application.ProcessMessages;
    if FIdFTP.Connected then
    begin
      FProgressBar.State := pbsNormal;
      FIdFTP.Get(AFTPPath, AFilePath, False, False);
      Result := True;
      FProgressBar.State := pbsPaused;
    end;
  except
    on e: Exception do
    begin
      AMessageException := e.Message;
      FProgressBar.State := pbsError;
      Result := False;
    end;
  end;
end;

function TFtp.SendFile(const ASourceFile, ADestFile: string;
  const AAppend: Boolean; const AStartPos: TIdStreamSize): Boolean;
var
  LSourceStream: TStream;
  LDestFileName : String;
begin
  LDestFileName := ADestFile;

  if LDestFileName = '' then begin
    LDestFileName := ExtractFileName(ASourceFile);
  end;

  LSourceStream := TIdReadFileNonExclusiveStream.Create(ASourceFile);

  try
    try
      FIdFTP.Put(LSourceStream, LDestFileName, AAppend, AStartPos);
    finally
      FreeAndNil(LSourceStream);
    end;
  except
    //
  end;

  Result := FileExists(LDestFileName, '*' + ExtractFileExt( LDestFileName ) );
end;

function TFtp.SendFile(AFTPPath, AFilePath, AFileName: TFileName;
  out AMessageException: String): Boolean;
begin
  try
    Application.ProcessMessages;
    if FIdFTP.Connected then
    begin

      FIdFTP.ChangeDir(AFtpPath);

      FThreadFTP := TThreadFTP.Create(FIdFTP, AFilePath, AFTPPath, AFileName);

      Result := True;
    end;
  except
    on e: Exception do
    begin
      AMessageException := e.Message;
      Result := False;
    end;
  end;

end;

function TFtp.TestConnection(AFTPPath: TFileName; out AMessageException: String): Boolean;
begin
  try
    if FIdFTP.Connected then
      FIdFTP.Disconnect;

    FIdFTP.Connect;
    if AFTPPath <> '' then
      FIdFTP.ChangeDir(AFTPPath);

    Result := FIdFTP.Connected;

    FIdFTP.Disconnect;
  except
    on E: Exception do
    begin
      try
        if FIdFTP.Connected then
          FIdFTP.Disconnect;

        FIdFTP.Connect;
        FIdFTP.ChangeDir('/');
        Result := FIdFTP.Connected;
        FIdFTP.Disconnect;
      except
        on e: Exception do
        begin
          FIdFTP.Disconnect;
          AMessageException := e.Message;
          Result := False;
        end;
      end;
    end;
  end;
end;

end.
