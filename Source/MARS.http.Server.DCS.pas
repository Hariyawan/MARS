(*
  Copyright 2016, MARS-Curiosity library

  Home: https://github.com/andrea-magni/MARS
*)
unit MARS.http.Server.DCS;

{$I MARS.inc}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.TimeSpan, DateUtils
, Net.CrossSocket.Base, Net.CrossSocket, Net.CrossHttpServer
, Net.CrossHttpMiddleware, Net.CrossHttpUtils
, MARS.Core.Engine, MARS.Core.Token
, MARS.Core.RequestAndResponse.Interfaces
;

type
  TMARSDCSRequest = class(TInterfacedObject, IMARSRequest)
  private
    FDCSRequest: ICrossHttpRequest;
  public
    // IMARSRequest ------------------------------------------------------------
    function AsObject: TObject;
    function GetAccept: string;
    function GetAuthorization: string;
    function GetContent: string;
    function GetCookieParamIndex(const AName: string): Integer;
    function GetCookieParamValue(const AIndex: Integer): string; overload;
    function GetCookieParamValue(const AName: string): string; overload;
    function GetFilesCount: Integer;
    function GetFormParamCount: Integer;
    function GetFormParamIndex(const AName: string): Integer;
    function GetFormParamName(const AIndex: Integer): string;
    function GetFormParamValue(const AIndex: Integer): string; overload;
    function GetFormParamValue(const AName: string): string; overload;
    function GetFormParams: string;
    function GetHeaderParamValue(const AHeaderName: string): string;
    function GetHostName: string;
    function GetMethod: string;
    function GetPort: Integer;
    function GetQueryParamIndex(const AName: string): Integer;
    function GetQueryParamValue(const AIndex: Integer): string;
    function GetQueryString: string;
    function GetRawContent: TBytes;
    function GetRawPath: string;
    // -------------------------------------------------------------------------
    constructor Create(ADCSRequest: ICrossHttpRequest); virtual;
  end;

  TMARSDCSResponse = class(TInterfacedObject, IMARSResponse)
  private
    FDCSResponse: ICrossHttpResponse;
  public
    // IMARSResponse -----------------------------------------------------------
    function GetContent: string;
    function GetContentEncoding: string;
    function GetContentStream: TStream;
    function GetContentType: string;
    function GetStatusCode: Integer;
    procedure SetContent(const AContent: string);
    procedure SetContentEncoding(const AContentEncoding: string);
    procedure SetContentStream(const AContentStream: TStream);
    procedure SetContentType(const AContentType: string);
    procedure SetHeader(const AName: string; const AValue: string);
    procedure SetStatusCode(const AStatusCode: Integer);
    procedure SetCookie(const AName, AValue, ADomain, APath: string; const AExpiration: TDateTime; const ASecure: Boolean);
    // -------------------------------------------------------------------------
    constructor Create(ADCSResponse: ICrossHttpResponse); virtual;
  end;


  TMARShttpServerDCS = class
  private
    FStoppedAt: TDateTime;
    FEngine: TMARSEngine;
    FStartedAt: TDateTime;
    FActive: Boolean;
    FDefaultPort: Integer;
    FHttpServer: ICrossHttpServer;
    function GetUpTime: TTimeSpan;
    procedure SetActive(const Value: Boolean);
    procedure SetDefaultPort(const Value: Integer);
  protected
    procedure Startup; virtual;
    procedure Shutdown; virtual;
  public
    constructor Create(AEngine: TMARSEngine); virtual;
    destructor Destroy; override;

    property Active: Boolean read FActive write SetActive;
    property DefaultPort: Integer read FDefaultPort write SetDefaultPort;
    property Engine: TMARSEngine read FEngine;
    property StartedAt: TDateTime read FStartedAt;
    property StoppedAt: TDateTime read FStoppedAt;
    property UpTime: TTimeSpan read GetUpTime;
  end;

implementation

uses
  Net.CrossHttpParams;

{ TMARShttpServerDCS }

constructor TMARShttpServerDCS.Create(AEngine: TMARSEngine);
begin
  inherited Create;
  FEngine := AEngine;
  FHttpServer := TCrossHttpServer.Create(0);
end;

destructor TMARShttpServerDCS.Destroy;
begin
  FHttpServer := nil;
  inherited;
end;

function TMARShttpServerDCS.GetUpTime: TTimeSpan;
begin
  if Active then
    Result := TTimeSpan.FromSeconds(SecondsBetween(FStartedAt, Now))
  else if StoppedAt > 0 then
    Result := TTimeSpan.FromSeconds(SecondsBetween(FStartedAt, FStoppedAt))
  else
    Result := TTimeSpan.Zero;
end;

procedure TMARShttpServerDCS.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    FActive := Value;
    if FActive then
      Startup
    else
      Shutdown;
  end;
end;

procedure TMARShttpServerDCS.SetDefaultPort(const Value: Integer);
begin
  FDefaultPort := Value;
end;

procedure TMARShttpServerDCS.Shutdown;
begin
  FHttpServer.Stop;

  FStoppedAt := Now;
end;

procedure TMARShttpServerDCS.Startup;
begin
  FHttpServer.Addr := IPv4v6_ALL; // IPv4v6
  FHttpServer.Port := DefaultPort;
  FHttpServer.Compressible := True;

  FHttpServer
//  .Get('/hello',
//    procedure(ARequest: ICrossHttpRequest; AResponse: ICrossHttpResponse)
//    begin
//      AResponse.Send('Hello World');
//    end)
  .All(FEngine.BasePath + '*',
    procedure(ARequest: ICrossHttpRequest; AResponse: ICrossHttpResponse; var AHandled: Boolean)
    begin
      AHandled := FEngine.HandleRequest(TMARSDCSRequest.Create(ARequest), TMARSDCSResponse.Create(AResponse))
    end
  );

  FHttpServer.Start;

  FStartedAt := Now;
  FStoppedAt := 0;
end;

{ TMARSDCSRequest }

function TMARSDCSRequest.AsObject: TObject;
begin
  Result := Self;
end;

constructor TMARSDCSRequest.Create(ADCSRequest: ICrossHttpRequest);
begin
  inherited Create;
  FDCSRequest := ADCSRequest;
end;

function TMARSDCSRequest.GetAccept: string;
begin
  Result := FDCSRequest.Accept;
end;

function TMARSDCSRequest.GetAuthorization: string;
begin
  Result := FDCSRequest.Authorization;
end;

function TMARSDCSRequest.GetContent: string;
begin
//AM TODO
  Result := '';
end;

function TMARSDCSRequest.GetCookieParamIndex(const AName: string): Integer;
var
  LIndex: Integer;
begin
  Result := -1;
  for LIndex := 0 to FDCSRequest.Cookies.Count -1 do
  begin
    if SameText(FDCSRequest.Cookies.Items[LIndex].Name, AName) then
    begin
      Result := LIndex;
      Break;
    end;
  end;
end;

function TMARSDCSRequest.GetCookieParamValue(const AName: string): string;
var
  LIndex: Integer;
  LCookie: TNameValue;
begin
  Result := '';
  for LIndex := 0 to FDCSRequest.Cookies.Count -1 do
  begin
    LCookie := FDCSRequest.Cookies.Items[LIndex];
    if SameText(LCookie.Name, AName) then
    begin
      Result := LCookie.Value;
      Break;
    end;
  end;
end;

function TMARSDCSRequest.GetCookieParamValue(const AIndex: Integer): string;
begin
  Result := FDCSRequest.Cookies.Items[AIndex].Value;
end;

function TMARSDCSRequest.GetFilesCount: Integer;
begin
//AM TODO
  Result := 0;
end;

function TMARSDCSRequest.GetFormParamCount: Integer;
begin
//AM TODO
  Result := 0;
end;

function TMARSDCSRequest.GetFormParamIndex(const AName: string): Integer;
begin
//AM TODO
  Result := -1;
end;

function TMARSDCSRequest.GetFormParamName(const AIndex: Integer): string;
begin
//AM TODO
  Result := '';
end;

function TMARSDCSRequest.GetFormParams: string;
begin
//AM TODO
  Result := '';
end;

function TMARSDCSRequest.GetFormParamValue(const AName: string): string;
begin
//AM TODO
  Result := '';
end;

function TMARSDCSRequest.GetFormParamValue(const AIndex: Integer): string;
begin
//AM TODO
  Result := '';
end;

function TMARSDCSRequest.GetHeaderParamValue(const AHeaderName: string): string;
begin
  Result := '';
  FDCSRequest.Header.GetParamValue(AHeaderName, Result);
end;

function TMARSDCSRequest.GetHostName: string;
begin
  Result := FDCSRequest.HostName;
end;

function TMARSDCSRequest.GetMethod: string;
begin
  Result := FDCSRequest.Method;
end;

function TMARSDCSRequest.GetPort: Integer;
begin
  Result := FDCSRequest.HostPort;
end;

function TMARSDCSRequest.GetQueryParamIndex(const AName: string): Integer;
var
  LIndex: Integer;
begin
  Result := -1;
  for LIndex := 0 to FDCSRequest.Query.Count -1 do
  begin
    if SameText(FDCSRequest.Query.Items[LIndex].Name, AName) then
    begin
      Result := LIndex;
      Break;
    end;
  end;
end;

function TMARSDCSRequest.GetQueryParamValue(const AIndex: Integer): string;
begin
  Result := FDCSRequest.Query.Items[AIndex].Value;
end;

function TMARSDCSRequest.GetQueryString: string;
begin
//AM TODO controllare
  Result := FDCSRequest.Query.ToString;
end;

function TMARSDCSRequest.GetRawContent: TBytes;
begin
  Result := [];
  case FDCSRequest.BodyType of
//    btNone: Result := [];
//    btUrlEncoded: ;
//    btMultiPart: Result := THttpMultiPartFormData(FDCSRequest.Body).Bytes;
    btBinary: Result := TBytesStream(FDCSRequest.Body).Bytes;
  end;
end;

function TMARSDCSRequest.GetRawPath: string;
begin
//AM TODO controllare RawPathAndParams?
  Result := FDCSRequest.Path;
end;

{ TMARSDCSResponse }

constructor TMARSDCSResponse.Create(ADCSResponse: ICrossHttpResponse);
begin
  inherited Create;
  FDCSResponse := ADCSResponse;
end;

function TMARSDCSResponse.GetContent: string;
begin
//AM TODO
end;

function TMARSDCSResponse.GetContentEncoding: string;
begin
//AM TODO
end;

function TMARSDCSResponse.GetContentStream: TStream;
begin
//AM TODO
end;

function TMARSDCSResponse.GetContentType: string;
begin
  Result := FDCSResponse.ContentType;
end;

function TMARSDCSResponse.GetStatusCode: Integer;
begin
  Result := FDCSResponse.StatusCode;
end;

procedure TMARSDCSResponse.SetContent(const AContent: string);
begin
  FDCSResponse.Send(AContent);
end;

procedure TMARSDCSResponse.SetContentEncoding(const AContentEncoding: string);
begin
//AM TODO
end;

procedure TMARSDCSResponse.SetContentStream(const AContentStream: TStream);
begin
  FDCSResponse.Send(AContentStream);
end;

procedure TMARSDCSResponse.SetContentType(const AContentType: string);
begin
  FDCSResponse.ContentType := AContentType;
end;

procedure TMARSDCSResponse.SetCookie(const AName, AValue, ADomain,
  APath: string; const AExpiration: TDateTime; const ASecure: Boolean);
begin
  FDCSResponse.Cookies.AddOrSet(AName, AValue, SecondsBetween(Now, AExpiration), APath, ADomain, False {AHttpOnly}, ASecure);
end;

procedure TMARSDCSResponse.SetHeader(const AName, AValue: string);
begin
  FDCSResponse.Header.Add(AName, AValue);
end;

procedure TMARSDCSResponse.SetStatusCode(const AStatusCode: Integer);
begin
  FDCSResponse.StatusCode := AStatusCode;
end;

end.