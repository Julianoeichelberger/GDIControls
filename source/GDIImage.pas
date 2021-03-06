unit GDIImage;

interface

uses
  Graphics, Classes, Winapi.ActiveX, GDI, GDICtrls, GDIUtils;

type
  TDrawMode = (dmStretch, dmSquare, dmRotate);

  TInterpolationMode = (imDefault, imLowQuality, imHighQuality, imBilinear,
    imBicubic, imNearestNeighbor, imHighQualityBilinear, imHighQualityBicubic);

  TGDIImage = class(TGDIPersistent)
  private
    FControl: TCustomCtrl;
    FPicture: TPicture;
    FInterpolation: TInterpolationMode;
    FDrawMode: TDrawMode;
    FPadding: Integer;
    FWidth: Integer;
    FHeight: Integer;
    FPosition: TGDIAlign;
    procedure SetPicture(const Value: TPicture);
    procedure SetInterpolation(const Value: TInterpolationMode);
    procedure SetDrawMode(const Value: TDrawMode);
    procedure SePadding(const Value: Integer);
    procedure SetHeight(const Value: Integer);
    procedure SetWidth(const Value: Integer);
    procedure SetPosition(const Value: TGDIAlign);
  protected
    procedure DrawStretch(AImage: IGPImage; AGPGraphics: IGPGraphics); virtual;
    procedure DrawSquare(AImage: IGPImage; AGPGraphics: IGPGraphics); virtual;
    procedure DrawRotate(AImage: IGPImage; AGPGraphics: IGPGraphics); virtual;
  public
    constructor Create(AControl: TCustomCtrl);
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;

    procedure Draw(AGPGraphics: IGPGraphics); override;
  published
    property DrawMode: TDrawMode read FDrawMode write SetDrawMode default dmStretch;
    property Interpolation: TInterpolationMode read FInterpolation write SetInterpolation default imDefault;
    property Picture: TPicture read FPicture write SetPicture;
    property Padding: Integer read FPadding write SePadding default 0;
    property Height: Integer read FHeight write SetHeight default 0;
    property Width: Integer read FWidth write SetWidth default 0;
    property Position: TGDIAlign read FPosition write SetPosition default gaCenter;
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
    Self.FPadding := TGDIImage(Source).Padding;
    Self.FWidth := TGDIImage(Source).Width;
    Self.FHeight := TGDIImage(Source).Height;
    Self.FPosition := TGDIImage(Source).Position;
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
  FPosition := gaCenter;
end;

destructor TGDIImage.Destroy;
begin
  FPicture.Free;
  inherited;
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
            DrawStretch(TGPImage.FromStream(Pstm), AGPGraphics);
          dmSquare:
            DrawSquare(TGPImage.FromStream(Pstm), AGPGraphics);
          dmRotate:
            DrawRotate(TGPImage.FromStream(Pstm), AGPGraphics);
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

procedure TGDIImage.DrawSquare(AImage: IGPImage; AGPGraphics: IGPGraphics);
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
    gaTop:
      AGPGraphics.DrawImage(AImage, (FControl.Width div 2) - (W div 2), FPadding, W, H);
    gaTopLeft:
      AGPGraphics.DrawImage(AImage, FPadding, FPadding, W, H);
    gaTopRight:
      AGPGraphics.DrawImage(AImage, FControl.Width - W - FPadding, FPadding, W, H);

    gaCenterLeft:
      AGPGraphics.DrawImage(AImage, FPadding, (FControl.Width div 2) - (W div 2), W, H);
    gaCenterRight:
      AGPGraphics.DrawImage(AImage, FControl.Width - W - FPadding, (FControl.Height div 2) - (H div 2), W, H);
    gaBotton:
      AGPGraphics.DrawImage(AImage, (FControl.Width div 2) - (W div 2), FControl.Height - H - FPadding, W, H);
    gaBottonLeft:
      AGPGraphics.DrawImage(AImage, FPadding, FControl.Height - H - FPadding, W, H);
    gaBottonRight:
      AGPGraphics.DrawImage(AImage, FControl.Width - W - FPadding, FControl.Height - H - FPadding, W, H);
  else
    AGPGraphics.DrawImage(AImage, (FControl.Width div 2) - (W div 2), (FControl.Height div 2) - (H div 2), W, H);
  end;
end;

procedure TGDIImage.DrawStretch(AImage: IGPImage; AGPGraphics: IGPGraphics);
begin
  AGPGraphics.DrawImage(AImage, FPadding, FPadding, FControl.Width - FPadding * 2, FControl.Height - FPadding * 2);
end;

procedure TGDIImage.DrawRotate(AImage: IGPImage; AGPGraphics: IGPGraphics);
const
  DEGS = 330;
var
  Matrix: IGPMatrix;
  Img_H, Img_W: Integer;
begin
  Img_H := FHeight;
  if Img_H = 0 then
    Img_H := FControl.Height div 2;
  Img_W := FWidth;
  if Img_W = 0 then
    Img_W := FControl.Width div 2;

  Matrix := TGPMatrix.Create;
  Matrix.RotateAt(DEGS, TGPPointF.Create(0.5 * Img_W, 0.5 * Img_H));
  AGPGraphics.SetTransform(Matrix);
  AGPGraphics.DrawImage(AImage, FControl.Width div 5, FControl.Height - (FControl.Height div 5), Img_W, Img_H);
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
    DoChange(Self);
  end;
end;

procedure TGDIImage.SetInterpolation(const Value: TInterpolationMode);
begin
  if FInterpolation <> Value then
  begin
    FInterpolation := Value;
    DoChange(Self);
  end;
end;

procedure TGDIImage.SePadding(const Value: Integer);
begin
  if FPadding <> Value then
  begin
    FPadding := Value;
    DoChange(Self);
  end;
end;

procedure TGDIImage.SetPicture(const Value: TPicture);
begin
  FPicture.Assign(Value);
  DoChange(Self);
end;

procedure TGDIImage.SetPosition(const Value: TGDIAlign);
begin
  if FPosition <> Value then
  begin
    FPosition := Value;
    DoChange(Self);
  end;
end;

procedure TGDIImage.SetWidth(const Value: Integer);
begin
  if FWidth <> Value then
  begin
    FWidth := Value;
    DoChange(Self);
  end;
end;

end.
