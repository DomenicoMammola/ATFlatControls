{
Copyright (C) Alexey Torgashin, uvviewsoft.com
License: MPL 2.0 or LGPL
}

unit ATFlatToolbar;

{$ifdef FPC}
{$mode delphi}{$H+}
{$endif}

interface

uses
  {$ifdef windows}
  Windows, Messages,
  {$endif}
  Classes, SysUtils, Graphics, Controls, ExtCtrls,
  ImgList, Menus, Math, Types,
  ATButtons,
  ATFlatThemes;

type
  { TATFlatToolbar }

  TATFlatToolbar = class(TCustomControl)
  private
    FImages: TImageList;
    FVertical: boolean;
    FButtonWidth: integer;
    FThemed: boolean; //for use in CudaText
    FWrapable: boolean;
    FOnMouseMove: TMouseMoveEvent;
    procedure PopupForDropdownClick(Sender: TObject);
    function GetButton(AIndex: integer): TATButton;
    procedure SetButtonWidth(AValue: integer);
    procedure SetVertical(AValue: boolean);
    procedure SetWrapable(AValue: boolean);
    procedure UpdateAnchors;
  protected
    procedure Resize; override;
    {$ifdef windows}
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    {$endif}
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CanFocus: boolean; override;
    function AddButton(
      AImageIndex: integer;
      AOnClick: TNotifyEvent;
      AOnRightClick: TContextPopupEvent;
      const ACaption, AHint, ADataString: string;
      AShowCaption: boolean): TATButton;
    function AddDropdown(
      AImageIndex: integer;
      AMenu: TPopupMenu;
      ADropdownEvent: TNotifyEvent=nil;
      const ACaption: string='';
      const AHint: string='';
      const ADataString: string=''): TATButton;
    function AddChoice(
      AOnClick: TNotifyEvent;
      AWidth: integer;
      AItems: TStrings;
      AItemIndex: integer;
      const AHint: string='';
      const ADataString: string=''): TATButton;
    function AddSep: TATButton;
    procedure UpdateControls(AInvalidate: boolean=false);
    function ButtonCount: integer;
    function ButtonWithMouseOver: integer;
    function IsIndexOk(AIndex: integer): boolean;
    property Buttons[AIndex: integer]: TATButton read GetButton;
    property Themed: boolean read FThemed write FThemed;
  published
    property Align;
    property Anchors;
    property AutoSize;
    {$ifdef FPC}
    property BorderSpacing;
    {$endif}
    //property ButtonWidth: integer read FButtonWidth write SetButtonWidth default 50;
    property Color;
    property Enabled;
    property Visible;
    property ShowHint;
    property ParentColor;
    property ParentShowHint;
    property Images: TImageList read FImages write FImages;
    property Vertical: boolean read FVertical write SetVertical default false;
    property Wrapable: boolean read FWrapable write SetWrapable default false;
    property OnMouseMove: TMouseMoveEvent read FOnMouseMove write FOnMouseMove;
  end;

implementation

{ TATFlatToolbar }

constructor TATFlatToolbar.Create(AOwner: TComponent);
begin
  inherited;
  AutoSize:= false;
  Width:= 200;
  Height:= 20;
  Caption:= '';
  Color:= clBtnFace;
  FImages:= nil;
  FVertical:= false;
  FButtonWidth:= 50;
  FWrapable:= false;
end;

destructor TATFlatToolbar.Destroy;
begin
  inherited;
end;

function TATFlatToolbar.CanFocus: boolean;
begin
  Result:= false;
end;

procedure TATFlatToolbar.UpdateControls(AInvalidate: boolean);
var
  btn: TATButton;
  ImgSize, i: integer;
begin
  if ControlCount=0 then exit;

  ImgSize:= 0;
  if Assigned(Images) then
    ImgSize:= Images.Width;

  FButtonWidth:= ImgSize+ATFlatTheme.GapForAutoSize;

  Canvas.Font.Name:= ATFlatTheme.FontName;
  Canvas.Font.Size:= ATFlatTheme.DoScaleFont(ATFlatTheme.FontSize);
  Canvas.Font.Quality:= ATFlatTheme.FontQuality;

  for i:= ControlCount-1 downto 0 do
  begin
    btn:= Controls[i] as TATButton;

    if Vertical then
      btn.Width:= ATFlatTheme.DoScale(FButtonWidth)
    else
    if Assigned(FImages) then
      btn.Height:= ATFlatTheme.DoScale(FButtonWidth);

    case btn.Kind of
      abuSeparatorVert:
        begin
          btn.Height:= 2*btn.PaddingBig;
        end;
      abuSeparatorHorz:
        begin
          btn.Width:= 2*btn.PaddingBig;
        end;

      abuIconOnly:
        begin
          if Vertical then
            btn.Height:= FButtonWidth
          else
            btn.Width:= FButtonWidth + IfThen(btn.Arrow, btn.Padding);
        end;

      abuTextOnly:
        begin
          if Vertical then
            btn.Height:= btn.GetTextSize(Canvas, btn.Caption).cy+ATFlatTheme.DoScale(2*btn.Padding)
          else
            btn.Width:= btn.GetTextSize(Canvas, btn.Caption).cx+ATFlatTheme.DoScale(2*btn.Padding);
        end;

      abuTextIconVert:
        begin
          if Vertical then
            btn.Height:= btn.GetTextSize(Canvas, btn.Caption).cy+ImgSize+ATFlatTheme.DoScale(2*btn.Padding)
          else
            btn.Width:= Max(btn.GetTextSize(Canvas, btn.Caption).cx, FButtonWidth);
        end;

      abuTextIconHorz:
        begin
          if Vertical then
            btn.Height:= Max(btn.GetTextSize(Canvas, btn.Caption).cy, FButtonWidth)
          else
            btn.Width:= btn.GetTextSize(Canvas, btn.Caption).cx+FButtonWidth+ATFlatTheme.DoScale(2*btn.Padding);
        end;

      abuTextChoice:
        begin
          btn.Width:= btn.WidthInitial;
          btn.Height:= FButtonWidth;
        end;
    end;

    if btn.Arrow then
    begin
      if not Vertical then
        btn.Width:= btn.Width+4*ATFlatTheme.ArrowSize;
      if Vertical and (btn.Caption='') and (btn.ImageIndex<0) then
        btn.Height:= btn.Height+4*ATFlatTheme.ArrowSize;
    end;

    //scale
    //horz bar: can be wrappable
    //vert bar: cannot be wrappable

    if Vertical then
      if not (btn.Kind in [abuTextIconVert]) then
        btn.Height:= ATFlatTheme.DoScale(btn.Height);

    if not Vertical then
    begin
      if not (btn.Kind in [abuTextOnly, abuTextIconHorz, abuTextIconVert]) then
        btn.Width:= ATFlatTheme.DoScale(btn.Width);
      btn.Height:= ATFlatTheme.DoScale(FButtonWidth);
    end;
  end;

  //anchor buttons in row
  UpdateAnchors;

  if AInvalidate then
    for i:= 0 to ControlCount-1 do
      Controls[i].Invalidate;

  for i:= 0 to ButtonCount-1 do
    Buttons[i].OnMouseMove:= FOnMouseMove;
end;

procedure TATFlatToolbar.UpdateAnchors;
var
  CtlSource, Ctl: TControl;
  akind, akind2: TAnchorKind;
  i: integer;
begin
  if ControlCount=0 then exit;
  CtlSource:= Controls[0];
  CtlSource.Left:= 0;
  CtlSource.Top:= 0;

  for i:= 1 to ControlCount-1 do
  begin
    Ctl:= Controls[i];

    //Wrapable supported only for horiz kind
    if Wrapable and
      (not Vertical) and
      (Controls[i-1].Left + Controls[i-1].Width + Ctl.Width >= ClientWidth) then
    begin
      {$ifdef FPC}
      Ctl.AnchorSide[akLeft].Control:= CtlSource;
      Ctl.AnchorSide[akTop].Control:= CtlSource;
      Ctl.AnchorSide[akLeft].Side:= asrLeft;
      Ctl.AnchorSide[akTop].Side:= asrBottom;
      {$endif}
      Ctl.Anchors:= [akLeft, akTop];
      CtlSource:= Ctl;
    end
    else
    begin
      if Vertical then
      begin
        akind:= akTop;
        akind2:= akLeft;
      end
      else
      begin
        akind:= akLeft;
        akind2:= akTop;
      end;

      {$ifdef FPC}
      Ctl.AnchorSide[akind].Control:= Controls[i-1];
      Ctl.AnchorSide[akind2].Control:= Controls[i-1];
      Ctl.AnchorSide[akind].Side:= asrRight;
      Ctl.AnchorSide[akind2].Side:= asrTop;
      {$endif}
      Ctl.Anchors:= [akLeft, akTop];
    end;
  end;
end;

procedure TATFlatToolbar.Resize;
begin
  inherited;
  if Wrapable and not Vertical then
    UpdateAnchors;
end;

function TATFlatToolbar.ButtonCount: integer;
begin
  Result:= ControlCount;
end;

{
//ok for win32, bad for linux gtk2 for CudaText plugin cuda_testing_dlg_proc
function TATFlatToolbar.ButtonWithMouseOver: integer;
var
  Btn: TATButton;
  i: integer;
begin
  Result:= -1;
  for i:= 0 to ButtonCount-1 do
  begin
    Btn:= Buttons[i];
    if Assigned(Btn) and Btn.IsMouseOver then
      exit(i);
  end;
end;
}

function TATFlatToolbar.ButtonWithMouseOver: integer;
var
  Btn: TATButton;
  P: TPoint;
  i: integer;
begin
  Result:= -1;
  P:= ScreenToClient(Mouse.CursorPos);
  for i:= 0 to ButtonCount-1 do
  begin
    Btn:= Buttons[i];
    if Btn=nil then Continue;
    if PtInRect(Btn.BoundsRect, P) then
      exit(i);
  end;
end;


function TATFlatToolbar.IsIndexOk(AIndex: integer): boolean;
begin
  Result:= (AIndex>=0) and (AIndex<ButtonCount);
end;

function TATFlatToolbar.GetButton(AIndex: integer): TATButton;
begin
  Result:= nil;
  if (AIndex>=0) and (AIndex<ControlCount) then
    if Controls[AIndex] is TATButton then
      Result:= Controls[AIndex] as TATButton;
end;

procedure TATFlatToolbar.SetButtonWidth(AValue: integer);
begin
  if FButtonWidth=AValue then Exit;
  FButtonWidth:= AValue;

  if Vertical then
    Width:= ATFlatTheme.DoScale(AValue)
  else
  if not Wrapable then
    Height:= ATFlatTheme.DoScale(AValue);
end;

procedure TATFlatToolbar.SetVertical(AValue: boolean);
begin
  if FVertical=AValue then Exit;
  FVertical:= AValue;
  UpdateControls;
end;

procedure TATFlatToolbar.SetWrapable(AValue: boolean);
begin
  if FWrapable=AValue then Exit;
  FWrapable:= AValue;
  UpdateControls;
end;

function TATFlatToolbar.AddButton(AImageIndex: integer;
  AOnClick: TNotifyEvent;
  AOnRightClick: TContextPopupEvent;
  const ACaption, AHint, ADataString: string; AShowCaption: boolean): TATButton;
var
  b: TATButton;
begin
  b:= TATButton.Create(Self);
  Result:= b;
  b.Parent:= Self;
  b.Focusable:= false;
  b.Flat:= true;
  b.Caption:= ACaption;
  b.Hint:= AHint;
  b.DataString:= ADataString;
  b.Images:= FImages;
  b.ImageIndex:= AImageIndex;
  b.ShowHint:= true;
  b.OnClick:= AOnClick;
  b.OnContextPopup:= AOnRightClick;

  if not AShowCaption then
    b.Kind:= abuIconOnly
  else
  if ACaption='' then
    b.Kind:= abuIconOnly
  else
  if AImageIndex<0 then
    b.Kind:= abuTextOnly
  else
  begin
    if Vertical then
      b.Kind:= abuTextIconVert
    else
      b.Kind:= abuTextIconHorz;
  end;
end;

function TATFlatToolbar.AddDropdown(AImageIndex: integer; AMenu: TPopupMenu;
  ADropdownEvent: TNotifyEvent; const ACaption: string; const AHint: string;
  const ADataString: string): TATButton;
var
  b: TATButton;
begin
  b:= TATButton.Create(Self);
  Result:= b;
  b.Parent:= Self;
  b.Images:= FImages;
  b.ImageIndex:= AImageIndex;
  b.Focusable:= false;
  b.Caption:= ACaption;
  b.Hint:= AHint;
  b.DataString:= ADataString;
  b.ShowHint:= true;
  b.Flat:= true;
  b.PopupMenu:= AMenu;
  b.Arrow:= true;
  if (b.Caption='') and (AImageIndex<0) then
    b.ArrowAlign:= taCenter
  else
    b.ArrowAlign:= taRightJustify;

  {$ifdef FPC}
  if not Assigned(ADropdownEvent) then
    b.OnClick:= PopupForDropdownClick
  else
  {$endif}
    b.OnClick:= ADropdownEvent;

  if AImageIndex>=0 then
  begin
    if b.Caption<>'' then
      if Vertical then
        b.Kind:= abuTextIconVert
      else
        b.Kind:= abuTextIconHorz
    else
      b.Kind:= abuIconOnly;
  end
  else
    b.Kind:= abuTextOnly;
end;

function TATFlatToolbar.AddChoice(AOnClick: TNotifyEvent; AWidth: integer;
  AItems: TStrings; AItemIndex: integer; const AHint: string;
  const ADataString: string): TATButton;
var
  b: TATButton;
begin
  b:= TATButton.Create(Self);
  Result:= b;
  b.Parent:= Self;
  b.Caption:= '';
  b.Width:= AWidth;
  b.WidthInitial:= AWidth;
  b.OnClick:= AOnClick;
  b.Focusable:= false;
  b.Flat:= true;
  b.Arrow:= true;
  b.ArrowAlign:= taRightJustify;
  b.Kind:= abuTextChoice;
  b.Items.AddStrings(AItems);
  b.ItemIndex:= AItemIndex;
  b.Hint:= AHint;
  b.DataString:= ADataString;
end;

function TATFlatToolbar.AddSep: TATButton;
var
  b: TATButton;
begin
  b:= TATButton.Create(Self);
  Result:= b;
  b.Parent:= Self;
  b.Focusable:= false;
  b.Caption:= '';
  b.Flat:= true;
  if Vertical then
    b.Kind:= abuSeparatorVert
  else
    b.Kind:= abuSeparatorHorz;
  b.Enabled:= false;
end;

type TControlHack = class(TControl);

procedure TATFlatToolbar.PopupForDropdownClick(Sender: TObject);
var
  C: TControl;
  P: TPoint;
begin
  C:= Sender as TControl;
  P:= C.ClientToScreen(Point(0, C.Height));
  TControlHack(C).PopupMenu.PopUp(P.X, P.Y);
end;

{$ifdef windows}
procedure TATFlatToolbar.WMEraseBkgnd(var Message: TWMEraseBkgnd);
var
  R: TRect;
begin
  //to avoid flickering with white on app startup
  if Message.DC<>0 then
  begin
    if ParentColor and Assigned(Parent) then
      Brush.Color:= Parent.Brush.Color
    else
      Brush.Color:= Color;
    R.Left:= 0;
    R.Top:= 0;
    R.Width:= Width;
    R.Height:= Height;
    Windows.FillRect(Message.DC, R, Brush.Reference.Handle);
  end;

  //to remove flickering on resize and mouse-over
  Message.Result:= 1;
end;
{$endif}

end.

