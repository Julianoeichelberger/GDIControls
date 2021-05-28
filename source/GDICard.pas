unit GDICard;

interface


uses
  Vcl.Controls, Vcl.Graphics, Winapi.Messages, Winapi.Windows, Vcl.Forms, System.Classes, System.SysUtils, System.Math,
  Winapi.ActiveX, Gdi, GDICtrls, GDIBadge, GDIStyle;

type
  TTextBoxAlign = (tbaBottom, tbaCenter, tbaTop);

  TTextBox = class(TPersistent)
  private
    FControl: TCustomCtrl;
    FAlign: TTextBoxAlign;
    FColor: TColor;
    FFont: TFont;
    FParentColor: Boolean;
    FOnChange: TNotifyEvent;
    FText: string;
    FPadding: Integer;
    procedure SetAlign(const Value: TTextBoxAlign);
    procedure SetColor(const Value: TColor);
    procedure SetFont(const Value: TFont);
    procedure SetParentColor(const Value: Boolean);
    procedure SetText(const Value: string);
    procedure DoChange;
    procedure SetOnChange(const Value: TNotifyEvent);
    procedure SetPadding(const Value: Integer);
    procedure Paint(GPGraphics: IGPGraphics);
  public
    constructor Create(AControl: TCustomCtrl);
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write SetOnChange;
  published
    property Align: TTextBoxAlign read FAlign write SetAlign default tbaBottom;
    property Color: TColor read FColor write SetColor default clDefault;
    property Font: TFont read FFont write SetFont;
    property ParentColor: Boolean read FParentColor write SetParentColor default True;
    property Text: string read FText write SetText;
    property Padding: Integer read FPadding write SetPadding default 0;
  end;

  TGDICustomCard = class(TCustomCtrl)
  private
    FPicture: TPicture;
    FValidCache: Boolean;
    FCache: IGPBitmap;
    DisableCache: Boolean;
    FDown: Boolean;
    FBadges: TBadgeCollection;
    FTextBox: TTextBox;
    FData: Pointer;
    FStyle: TGDIStyle;
    procedure Changed;
    procedure SetPicture(Value: TPicture);
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMDialogChar(var Message: TCMDialogChar); message CM_DIALOGCHAR;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure InvalidateCache;
    procedure DoChanged(Sender: TObject);
    procedure SetTextBox(const Value: TTextBox);
    procedure SetBadges(const Value: TBadgeCollection);
    procedure SetStyle(const Value: TGDIStyle);
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;

    property Constraints;
    property Data: Pointer read FData write FData;

    property Badges: TBadgeCollection read FBadges write SetBadges;
    property Picture: TPicture read FPicture write SetPicture;
    property TextBox: TTextBox read FTextBox write SetTextBox;
    property Style: TGDIStyle read FStyle write SetStyle;
  end;

  TGDICard = class(TGDICustomCard)
  published
    property Align;
    property Anchors;
    property Badges;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentFont;
    property ParentShowHint;
    property Picture;
    property PopupMenu;
    property ShowHint;
    property Style;
    property TextBox;
    property Visible;

    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
  end;

implementation

uses
  GDIUtils;

{ TTextBox }

procedure TTextBox.Assign(Source: TPersistent);
begin
  if Source is TTextBox then
  begin
    Self.FColor := TTextBox(Source).Color;
    Self.FParentColor := TTextBox(Source).ParentColor;
    Self.FAlign := TTextBox(Source).Align;
    Self.FPadding := TTextBox(Source).Padding;
    Self.FText := TTextBox(Source).Text;
  end
  else
    inherited;
end;

constructor TTextBox.Create(AControl: TCustomCtrl);
begin
  FControl := AControl;
  FFont := TFont.Create;
  FAlign := tbaBottom;
  FParentColor := True;
  FColor := clDefault;
  FPadding := 0;
end;

destructor TTextBox.Destroy;
begin
  FFont.Free;
  inherited;
end;

procedure TTextBox.DoChange;
begin
  if Assigned(FOnChange) then
    OnChange(Self);
end;

procedure TTextBox.Paint(GPGraphics: IGPGraphics);
var
  GPGraphicsPath: IGPGraphicsPath;
  Fontx: IGPFont;
  GPSolidBrush: IGPSolidBrush;
  Rectf: TGPRectF;
  StringFormat: IGPStringFormat;
  Pointx: TGPPointF;

begin
  if FText.IsEmpty then
    exit;

  FControl.Canvas.Font.Assign(FControl.Font);

  Fontx := TGPFont.CreateByFont(FControl.Canvas.Handle, FControl.Font);

  Rectf := GPGraphics.MeasureString(FText, Fontx, TGPRectF.Create(0, 0, FControl.Width, FControl.Height));

  if not FParentColor then
  begin
    GPSolidBrush := TGPSolidBrush.Create(ColorToGPColor(FColor));
    GPGraphicsPath := TGPGraphicsPath.Create;
    GPGraphicsPath.Reset;

    case FAlign of
      tbaBottom:
        GPGraphicsPath.AddRectangle(TGPRectF.Create(
          FPadding,
          FControl.ClientHeight - (Rectf.Height + 10),
          FControl.ClientWidth - (FPadding * 2),
          Rectf.Height + 10)
          );
      tbaCenter:
        GPGraphicsPath.AddRectangle(TGPRectF.Create(FPadding,
          (FControl.ClientHeight / 2) - ((Rectf.Height + 10) / 2),
          FControl.ClientWidth - (FPadding * 2),
          Rectf.Height + 10)
          );
      tbaTop:
        GPGraphicsPath.AddRectangle(TGPRectF.Create(FPadding,
          0,
          FControl.ClientWidth - (FPadding * 2),
          Rectf.Height + 10)
          );
    end;
    GPGraphicsPath.CloseFigure;
    GPGraphics.FillPath(GPSolidBrush, GPGraphicsPath);
  end;
  GPSolidBrush := TGPSolidBrush.Create(TGPColor.CreateFromColorRef(FFont.Color));

  StringFormat := TGPStringFormat.GenericDefault;
  StringFormat.Alignment := StringAlignmentCenter;
  StringFormat.Trimming := StringTrimmingEllipsisPath;

  case FAlign of
    tbaBottom:
      GPGraphics.DrawString(FText, Fontx,
        TGPRectF.Create(TGPPointF.Create(0, (FControl.ClientHeight - (Rectf.Height + 5))),
        TGPSizeF.Create(FControl.ClientWidth, FControl.ClientHeight - (FControl.ClientHeight - (Rectf.Height + 5)))),
        StringFormat, GPSolidBrush);
    tbaCenter:
      begin
        Pointx.X := 0;
        Pointx.Y := ((FControl.Height) / 2) - (Rectf.Height / 2);
        GPGraphics.DrawString(FText, Fontx, TGPRectF.Create(Pointx, TGPSizeF.Create(FControl.ClientWidth,
          FControl.ClientHeight - Pointx.Y)), StringFormat, GPSolidBrush);
      end;
    tbaTop:
      begin
        GPGraphics.DrawString(FText, Fontx,
          TGPRectF.Create(TGPPointF.Create(0, 5),
          TGPSizeF.Create(FControl.ClientWidth, FControl.ClientHeight - (FControl.ClientHeight - (Rectf.Height + 5)))),
          StringFormat, GPSolidBrush);
      end;
  end;
end;

procedure TTextBox.SetAlign(const Value: TTextBoxAlign);
begin
  if FAlign <> Value then
  begin
    FAlign := Value;
    DoChange;
  end;
end;

procedure TTextBox.SetColor(const Value: TColor);
begin
  if FColor <> Value then
  begin
    FColor := Value;
    DoChange;
  end;
end;

procedure TTextBox.SetFont(const Value: TFont);
begin
  FFont.Assign(Value);
end;

procedure TTextBox.SetOnChange(const Value: TNotifyEvent);
begin
  FOnChange := Value;
  FFont.OnChange := Value;
end;

procedure TTextBox.SetPadding(const Value: Integer);
begin
  if FPadding <> Value then
  begin
    FPadding := Value;
    DoChange;
  end;
end;

procedure TTextBox.SetParentColor(const Value: Boolean);
begin
  if FParentColor <> Value then
  begin
    FParentColor := Value;
    DoChange;
  end;
end;

procedure TTextBox.SetText(const Value: string);
begin
  if FText <> Value then
  begin
    FText := Value;
    DoChange;
  end;
end;

{ TZSProductButton }

procedure TGDICustomCard.Changed;
begin
  FValidCache := false;
  Invalidate;
end;

procedure TGDICustomCard.CMDialogChar(var Message: TCMDialogChar);
begin
  with Message do
    if IsAccel(CharCode, Caption) and CanFocus then
    begin
      FDown := True;
      Repaint;
      Click;
      FDown := false;
      Repaint;
      Result := 1;
    end
    else
      inherited;
end;

procedure TGDICustomCard.CMFontChanged(var Message: TMessage);
begin
  inherited;
  Changed;
end;

procedure TGDICustomCard.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  Changed;
end;

procedure TGDICustomCard.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  Changed;
end;

procedure TGDICustomCard.CMTextChanged(var Message: TMessage);
begin
  inherited;
  Changed;
end;

constructor TGDICustomCard.Create(AOwner: TComponent);
begin
  inherited;
  FStyle := TGDIStyle.Create(Self);
  FStyle.OnChange := DoChanged;

  FBadges := TBadgeCollection.Create(Self, TBadge);
  FBadges.OnChange := DoChanged;

  FTextBox := TTextBox.Create(Self);
  FTextBox.OnChange := DoChanged;

  DoubleBuffered := True;
  Constraints.MinHeight := 1;
  Constraints.MinWidth := 1;
  DisableCache := True;
  Width := 213;
  Height := 104;
  DisableCache := false;
  Font.Color := clWhite;
  Font.Name := 'Arial';
  Font.Style := [fsBold];
  FDown := false;
  FPicture := TPicture.Create;
  FPicture.OnChange := DoChanged;
  FCache := TGPBitmap.Create(Width, Height, PixelFormat32bppARGB);
end;

destructor TGDICustomCard.Destroy;
begin
  FreeAndNil(FPicture);
  FTextBox.Free;
  FBadges.Free;
  FStyle.Free;
  inherited;
end;

procedure TGDICustomCard.InvalidateCache;
begin
  if not HandleAllocated then
    exit;

  if DisableCache then
    exit;

  FCache := TGPBitmap.Create(Width, Height);
  FValidCache := false;
end;

procedure TGDICustomCard.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  SetBounds(Left + 1, Top + 1, Width - 2, Height - 2);
  FDown := True;
  Changed;
  inherited MouseDown(Button, Shift, X, Y);
end;

procedure TGDICustomCard.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  SetBounds(Left - 1, Top - 1, Width + 2, Height + 2);
  FDown := false;
  Changed;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TGDICustomCard.Paint;

  procedure BeginPaint;
  var
    CR: TRect;
    rgn1: HRGN;
    i: Integer;
    p: TPoint;
  begin
    CR := ClientRect;
    rgn1 := CreateRectRgn(CR.Left, CR.Top, CR.Right, CR.Bottom);
    try
      SelectClipRgn(Canvas.Handle, rgn1);

      i := SaveDC(Canvas.Handle);
      p := ClientOrigin;
      Winapi.Windows.ScreenToClient(Parent.Handle, p);
      p.X := -p.X;
      p.Y := -p.Y;
      MoveWindowOrg(Canvas.Handle, p.X, p.Y);

      SendMessage(Parent.Handle, WM_ERASEBKGND, Canvas.Handle, 0);
      SendMessage(Parent.Handle, WM_PAINT, Canvas.Handle, 0);

      Parent.PaintCtrls(Canvas.Handle, nil);
      RestoreDC(Canvas.Handle, i);
      SelectClipRgn(Canvas.Handle, 0);
    finally
      DeleteObject(rgn1);
    end;
  end;

var
  pcbWrite: Integer;
  GPGraphics: IGPGraphics;
  GPGraphicsPath: IGPGraphicsPath;
  ImageSize: TSize;
  Stream: TMemoryStream;
  Pstm: IStream;
  Hr: HRESULT;
  hGlobal: THandle;
  GPImage: IGPImage;
begin
  BeginPaint;
  if not FValidCache then
  begin
    GPGraphicsPath := TGPGraphicsPath.Create;
    GPGraphicsPath.Reset;
    GPGraphicsPath.AddRectangle(TGPRectF.Create(0, 0, ClientWidth, ClientHeight));
    GPGraphicsPath.CloseFigure;

    GPGraphics := TGPGraphics.Create(FCache);
    GPGraphics.SmoothingMode := SmoothingModeAntiAlias;
    GPGraphics.TextRenderingHint := TextRenderingHintClearTypeGridFit;
    GPGraphics.FillPath(FStyle.GradientBrush, GPGraphicsPath);

    if Picture.Graphic <> nil then
    begin

      ImageSize.Width := Picture.Width;
      ImageSize.Height := Picture.Height;
      ImageSize.Width := Width;
      ImageSize.Height := Height;

      Stream := TMemoryStream.Create;
      Picture.Graphic.SaveToStream(Stream);
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
          GPImage := TGPImage.FromStream(Pstm);

          GPGraphics.InterpolationMode := InterpolationModeHighQuality;

          GPGraphics.DrawImage(GPImage, ((Width) / 2) - (ImageSize.Width / 2), ((Height) / 2) - (ImageSize.Height / 2),
            ImageSize.Width, ImageSize.Height);
        end;
        Pstm := nil;
      end
      else
        GlobalFree(hGlobal);

      Stream.Free;
    end;

    FBadges.Paint(GPGraphics);
    FTextBox.Paint(GPGraphics);

    FValidCache := True;
  end;

  if FValidCache then
  begin
    GPGraphics := TGPGraphics.Create(Canvas.Handle);
    GPGraphics.DrawImage(FCache, 0, 0);
  end;
end;

procedure TGDICustomCard.DoChanged(Sender: TObject);
begin
  Changed;
end;

procedure TGDICustomCard.Resize;
begin
  inherited;
  InvalidateCache;
end;

procedure TGDICustomCard.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited;
  InvalidateCache;
end;

procedure TGDICustomCard.SetPicture(Value: TPicture);
begin
  FPicture.Assign(Value);
  Changed;
end;

procedure TGDICustomCard.SetStyle(const Value: TGDIStyle);
begin
  FStyle.Assign(Value);
end;

procedure TGDICustomCard.SetBadges(const Value: TBadgeCollection);
begin
  FBadges.Assign(Value);
end;

procedure TGDICustomCard.SetTextBox(const Value: TTextBox);
begin
  FTextBox.Assign(Value)
end;

procedure TGDICustomCard.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  if TabStop then
    Message.Result := DLGC_WANTALLKEYS or DLGC_WANTARROWS
  else
    Message.Result := 0;
end;

procedure TGDICustomCard.WMPaint(var Message: TWMPaint);
var
  DC, MemDC: HDC;
  MemBitmap, OldBitmap: HBITMAP;
  PS: TPaintStruct;
begin
  if not FDoubleBuffered or (Message.DC <> 0) then
  begin
    if not(csCustomPaint in ControlState) and (ControlCount = 0) then
      inherited
    else
      PaintHandler(Message);
  end
  else
  begin
    DC := GetDC(0);
    if DC <> 0 then
    begin
      MemBitmap := CreateCompatibleBitmap(DC, ClientRect.Right, ClientRect.Bottom);
      ReleaseDC(0, DC);
      MemDC := CreateCompatibleDC(0);
      OldBitmap := SelectObject(MemDC, MemBitmap);
      try
        DC := BeginPaint(Handle, PS);
        Perform(WM_ERASEBKGND, MemDC, MemDC);
        Message.DC := MemDC;
        WMPaint(Message);
        Message.DC := 0;
        BitBlt(DC, 0, 0, ClientRect.Right, ClientRect.Bottom, MemDC, 0, 0, SRCCOPY);
        EndPaint(Handle, PS);
      finally
        SelectObject(MemDC, OldBitmap);
        DeleteDC(MemDC);
        DeleteObject(MemBitmap);
      end;
    end;
  end;
end;

end.
