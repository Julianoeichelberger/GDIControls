unit GDIImage;

interface

uses
  Graphics, Classes, Winapi.ActiveX,
  GDI, GDICtrls, GDIUtils;

type
  TDrawMode = (dmStretch, dmSquare);

  TInterpolationMode = (imDefault, imLowQuality, imHighQuality, imBilinear,
    imBicubic, imNearestNeighbor, imHighQualityBilinear, imHighQualityBicubic);

  TImagePosition = (
    ipCenter, ipCenterLeft, ipCenterRight,
    ipTop, ipTopLeft, ipTopRight,
    ipBotton, ipBottonLeft, ipBottonRight);

  TGDIImage = class(TPersistent)
  private
    FControl: TCustomCtrl;
    FPicture: TPicture;
    FInterpolation: TInterpolationMode;
    FDrawMode: TDrawMode;
    FOnChange: TNotifyEvent;
    FPadding: Integer;
    FWidth: Integer;
    FHeight: Integer;
    FPosition: TImagePosition;
    procedure SetPicture(const Value: TPicture);
    procedure SetInterpolation(const Value: TInterpolationMode);
    procedure SetDrawMode(const Value: TDrawMode);
    procedure SePadding(const Value: Integer);
    procedure DoChange;
    procedure SetHeight(const Value: Integer);
    procedure SetWidth(const Value: Integer);
    procedure SetPosition(const Value: TImagePosition);
  protected
    procedure DrawStretchImage(AImage: IGPImage; AGPGraphics: IGPGraphics); virtual;
    procedure DrawSquareImage(AImage: IGPImage; AGPGraphics: IGPGraphics); virtual;
  public
    constructor Create(AControl: TCustomCtrl);
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;

    procedure Draw(AGPGraphics: IGPGraphics);

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property DrawMode: TDrawMode read FDrawMode write SetDrawMode default dmStretch;
    property Interpolation: TInterpolationMode read FInterpolation write SetInterpolation default imDefault;
    property Picture: TPicture read FPicture write SetPicture;
    property Padding: Integer read FPadding write SePadding default 0;
    property Height: Integer read FHeight write SetHeight default 0;
    property Width: Integer read FWidth write SetWidth default 0;
    property Position: TImagePosition read FPosition write SetPosition default ipCenter;
  end;

implementation

Uses
  Windows, Math, SysUtils;

{ TGDIImage }

procedure TGDIImage.Assign(Source: TPersistent);
begin
  if Source is TGDIImage then
  begin
    Self.FInterpolation := TGDIImage(Source).Interpolation;
    Self.FDrawMode := TGDIImage(Source).DrawMode;
  end
  else
    inherited;
end;

constructor TGDIImage.Create(AControl: TCustomCtrl);
begin
  FPicture := TPicture.Create;
  FControl := AControl;
  FInterpolation := imDefault;
  FDrawMode := dmStretch;
  FPadding := 0;
  FHeight := 0;
  FWidth := 0;
  FPosition := ipCenter;
end;

destructor TGDIImage.Destroy;
begin
  FPicture.Free;
  inherited;
end;

procedure TGDIImage.DoChange;
begin
  if Assigned(FOnChange) then
    OnChange(Self);
end;

procedure TGDIImage.Draw(AGPGraphics: IGPGraphics);
var
  Stream: TMemoryStream;
  Pstm: IStream;
  Hr: HRESULT;
  pcbWrite: Integer;
  hGlobal: THandle;
begin
  if not Assigned(FPicture.Graphic) then
    exit;

  Stream := TMemoryStream.Create;
  try
    FPicture.Graphic.SaveToStream(Stream);
    Stream.Seek(0, soFromBeginning);

    hGlobal := GlobalAlloc(GMEM_MOVEABLE, Stream.Size);

    Pstm := nil;
    Hr := CreateStreamOnHGlobal(hGlobal, True, Pstm);
    if (Hr = S_OK) then
    begin
      pcbWrite := 0;
      Pstm.Write(Stream.Memory, Stream.Size, @pcbWrite);

      if (Stream.Size = pcbWrite) then
      begin
        AGPGraphics.InterpolationMode := TGPInterpolationMode(Ord(FInterpolation));
        case FDrawMode of
          dmStretch:
            DrawStretchImage(TGPImage.FromStream(Pstm), AGPGraphics);
          dmSquare:
            DrawSquareImage(TGPImage.FromStream(Pstm), AGPGraphics);
        end;
      end;
      Pstm := nil;
    end
    else
      GlobalFree(hGlobal);
  finally
    Stream.Free;
  end;
end;

procedure TGDIImage.DrawSquareImage(AImage: IGPImage; AGPGraphics: IGPGraphics);
var
  H, W: Integer;
begin
  H := FHeight;
  if H = 0 then
    H := FControl.Height div 3;
  W := FWidth;
  if W = 0 then
    W := FControl.Width div 3;

  case FPosition of
    ipTop:
      AGPGraphics.DrawImage(AImage, (FControl.Width div 2) - (W div 2), FPadding, W, H);
    ipTopLeft:
      AGPGraphics.DrawImage(AImage, FPadding, FPadding, W, H);
    ipTopRight:
      AGPGraphics.DrawImage(AImage, FControl.Width - W - FPadding, FPadding, W, H);

    ipCenterLeft:
      AGPGraphics.DrawImage(AImage, FPadding, (FControl.Width div 2) - (W div 2), W, H);
    ipCenterRight:
      AGPGraphics.DrawImage(AImage, FControl.Width - W - FPadding, (FControl.Height div 2) - (H div 2), W, H);
    ipBotton:
      AGPGraphics.DrawImage(AImage, (FControl.Width div 2) - (W div 2), FControl.Height - H - FPadding, W, H);
    ipBottonLeft:
      AGPGraphics.DrawImage(AImage, FPadding, FControl.Height - H - FPadding, W, H);
    ipBottonRight:
      AGPGraphics.DrawImage(AImage, FControl.Width - W - FPadding, FControl.Height - H - FPadding, W, H);
  else
    AGPGraphics.DrawImage(AImage, (FControl.Width div 2) - (W div 2), (FControl.Height div 2) - (H div 2), W, H);
  end;
end;

procedure TGDIImage.DrawStretchImage(AImage: IGPImage; AGPGraphics: IGPGraphics);
begin
  AGPGraphics.DrawImage(AImage, FPadding, FPadding, FControl.Width - FPadding * 2, FControl.Height - FPadding * 2);
end;

procedure TGDIImage.SetDrawMode(const Value: TDrawMode);
begin
  if FDrawMode <> Value then
    FDrawMode := Value;
end;

procedure TGDIImage.SetHeight(const Value: Integer);
begin
  if FHeight <> Value then
  begin
    FHeight := Value;
    DoChange;
  end;
end;

procedure TGDIImage.SetInterpolation(const Value: TInterpolationMode);
begin
  if FInterpolation <> Value then
  begin
    FInterpolation := Value;
    DoChange;
  end;
end;

procedure TGDIImage.SePadding(const Value: Integer);
begin
  if FPadding <> Value then
  begin
    FPadding := Value;
    DoChange;
  end;
end;

procedure TGDIImage.SetPicture(const Value: TPicture);
begin
  FPicture.Assign(Value);
  DoChange;
end;

procedure TGDIImage.SetPosition(const Value: TImagePosition);
begin
  if FPosition <> Value then
  begin
    FPosition := Value;
    DoChange;
  end;
end;

procedure TGDIImage.SetWidth(const Value: Integer);
begin
  if FWidth <> Value then
  begin
    FWidth := Value;
    DoChange;
  end;
end;

end.
