(*
  Copyright 2016, MARS-Curiosity library

  Home: https://github.com/andrea-magni/MARS
*)
unit MARS.Data.FireDAC.ReadersAndWriters;

{$I MARS.inc}

interface

uses
  Classes, SysUtils, Rtti

  , DB

  , MARS.Core.Attributes
  , MARS.Core.Activation.Interfaces
  , MARS.Core.Declarations
  , MARS.Core.MediaType
  , MARS.Core.Classes
  , MARS.Core.MessageBodyWriter
  , MARS.Core.MessageBodyReader
  , MARS.Core.Utils
  , MARS.Data.Utils;

type
  // --- READERS ---
  [ Consumes(TMediaType.APPLICATION_JSON_FIREDAC) ]
  TArrayFDMemTableReader = class(TInterfacedObject, IMessageBodyReader)
  public
    function ReadFrom(
    {$ifdef Delphi10Berlin_UP}const AInputData: TBytes;{$else}const AInputData: AnsiString;{$endif}
      const ADestination: TRttiObject; const AMediaType: TMediaType;
      const AActivation: IMARSActivation
    ): TValue; virtual;
  end;

  // --- WRITERS ---
  [ Produces(TMediaType.APPLICATION_XML)
  , Produces(TMediaType.APPLICATION_JSON_FIREDAC)
  , Produces(TMediaType.APPLICATION_OCTET_STREAM)
  ]
  TFDAdaptedDataSetWriter = class(TInterfacedObject, IMessageBodyWriter)
    procedure WriteTo(const AValue: TValue; const AMediaType: TMediaType;
      AOutputStream: TStream; const AActivation: IMARSActivation);
  end;

  [ Produces(TMediaType.APPLICATION_JSON_FIREDAC) ]
  TArrayFDCustomQueryWriter = class(TInterfacedObject, IMessageBodyWriter)
    procedure WriteTo(const AValue: TValue; const AMediaType: TMediaType;
      AOutputStream: TStream; const AActivation: IMARSActivation);
  end;


implementation

uses
    Generics.Collections
  , FireDAC.Comp.Client, FireDAC.Comp.DataSet
  , FireDAC.Stan.Intf

  , FireDAC.Stan.StorageBIN
  , FireDAC.Stan.StorageJSON
  , FireDAC.Stan.StorageXML

  , MARS.Core.JSON
  , MARS.Core.MessageBodyWriters, MARS.Core.MessageBodyReaders
  {$ifdef DelphiXE7_UP}, System.JSON {$endif}
  , MARS.Core.Exceptions
  , MARS.Rtti.Utils, MARS.Data.FireDAC.Utils
;

{ TArrayFDCustomQueryWriter }

procedure TArrayFDCustomQueryWriter.WriteTo(const AValue: TValue; const AMediaType: TMediaType;
  AOutputStream: TStream; const AActivation: IMARSActivation);
var
  LResult: TJSONObject;
begin
  LResult := TFDDataSets.ToJSON(AValue.AsType<TArray<TFDDataSet>>);
  try
    TJSONValueWriter.WriteJSONValue(LResult, AMediaType, AOutputStream, AActivation);
  finally
    LResult.Free;
  end;
end;

{ TFDAdaptedDataSetWriter }

procedure TFDAdaptedDataSetWriter.WriteTo(const AValue: TValue; const AMediaType: TMediaType;
  AOutputStream: TStream; const AActivation: IMARSActivation);
var
  LDataset: TFDAdaptedDataSet;
  LStorageFormat: TFDStorageFormat;
begin
  LDataset := AValue.AsType<TFDAdaptedDataSet>;

  if AMediaType.Matches(TMediaType.APPLICATION_XML) then
    LDataSet.SaveToStream(AOutputStream, sfXML)
  else if AMediaType.Matches(TMediaType.APPLICATION_JSON_FireDAC) then
    StringToStream(AOutputStream, TFDDataSets.DataSetToEncodedBinaryString(LDataSet), TEncoding.UTF8)
  else if AMediaType.Matches(TMediaType.APPLICATION_OCTET_STREAM) then
    LDataSet.SaveToStream(AOutputStream, sfBinary)
  else
    raise EMARSException.CreateFmt('Unsupported media type: %s', [AMediaType.ToString]);
end;

{ TArrayFDMemTableReader }

function TArrayFDMemTableReader.ReadFrom(
{$ifdef Delphi10Berlin_UP}const AInputData: TBytes;{$else}const AInputData: AnsiString;{$endif}
  const ADestination: TRttiObject; const AMediaType: TMediaType;
  const AActivation: IMARSActivation
): TValue;
var
  LJSON: TJSONObject;
begin
  Result := TValue.Empty;

  LJSON := TJSONValueReader.ReadJSONValue(AInputData, ADestination, AMediaType, AActivation).AsType<TJSONObject>;
  if not Assigned(LJSON) then
    Exit;
  try
    Result := TValue.From<TArray<TFDMemTable>>(TFDDataSets.FromJSON(LJSON));
  finally
    LJSON.Free;
  end;
end;

procedure RegisterReadersAndWriters;
begin
  TMARSMessageBodyRegistry.Instance.RegisterWriter<TFDAdaptedDataSet>(TFDAdaptedDataSetWriter);

  TMARSMessageBodyRegistry.Instance.RegisterWriter(
    TArrayFDCustomQueryWriter
  , function (AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: string): Boolean
    begin
      Result := Assigned(AType) and AType.IsDynamicArrayOf<TFDDataSet>;
    end
  , function (AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: string): Integer
    begin
      Result := TMARSMessageBodyRegistry.AFFINITY_MEDIUM;
    end
  );

  TMARSMessageBodyReaderRegistry.Instance.RegisterReader(
    TArrayFDMemTableReader
  , function(AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: string): Boolean
    begin
      Result := Assigned(AType) and AType.IsDynamicArrayOf<TFDMemTable>;
    end
  , function (AType: TRttiType; const AAttributes: TAttributeArray; AMediaType: string): Integer
    begin
      Result := TMARSMessageBodyRegistry.AFFINITY_MEDIUM
    end
  );
end;

initialization
  RegisterReadersAndWriters;

end.
