unit main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.ExtCtrls, FMX.Menus, FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls,
  System.UIConsts, FMX.Effects, FMX.Types3D, ShlWapi,
  System.Math.Vectors, FMX.Controls3D, FMX.Layers3D, FMX.Viewport3D,
  JclCompression, JclStrings, w2xconvunit, ocv.highgui_c, ocv.core_c,
  ocv.core.types_c, ocv.imgproc_c, ocv.imgproc.types_c, StrUtils, Winapi.Activex
  ;

type
  TFileSorter = class(TStringList)
  protected
    function CompareStrings(const S1, S2: string): Integer; override;
  end;

  TImageThread = class(TThread)
  private
    FImage: TImage;
    FTempBitmap: TBitmap;
    FFilename: TMemoryStream;
    Pictures: array of TBitmap;
  protected
    procedure Execute; override;
    procedure Finished;
  public
    constructor Create(const AImage: TImage; const AStream: TMemoryStream);
    destructor Destroy; override;
  end;

  TForm2 = class(TForm)
    ImageViewer1: TImageViewer;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    mnuOpen: TMenuItem;
    MenuItem3: TMenuItem;
    ScrollBox1: TScrollBox;
    TrackBar1: TTrackBar;
    OpenDialog1: TOpenDialog;
    Viewport3D1: TViewport3D;
    Coverflow: TLayout3D;
    Rectangle1: TRectangle;
    StyleBook1: TStyleBook;
    RoundRect1: TRoundRect;
    TrackBar2: TTrackBar;
    AniIndicator1: TAniIndicator;
    PopupMenu1: TPopupMenu;
    MenuItem2: TMenuItem;
    ImageViewer2: TImageViewer;
    Rectangle2: TRectangle;
    Splitter1: TSplitter;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem14: TMenuItem;
    MenuItem15: TMenuItem;
    MenuItem16: TMenuItem;
    MenuItem17: TMenuItem;
    MenuItem18: TMenuItem;
    MenuItem19: TMenuItem;
    MenuItem20: TMenuItem;
    procedure MenuItem3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ImageViewer1MouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; var Handled: Boolean);
    procedure TrackBar1Tracking(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure mnuOpenClick(Sender: TObject);
    procedure TrackBar2Change(Sender: TObject);
    procedure CoverflowMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; var Handled: Boolean);
    procedure MenuItem2Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
  { Private declarations }
    CoverIndex: Integer;

    FScalePicture: Single;
    procedure SetScalePicture(const Value: Single);

    procedure SetCoverIndex(AIndex: Integer);
    procedure DoCoverMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
  public
    { Public declarations }
    procedure HelpContentBounds(Sender: TObject; var CBounds: TRectF);
    property ScalePicture:Single read FScalePicture write SetScalePicture;
  end;

var
  Form2: TForm2;

implementation

uses
  FMX.InertialMovement;

type
  THelpImageView = class(TScrollBox);

{$R *.fmx}

procedure TForm2.CoverflowMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; var Handled: Boolean);
begin
  TrackBar2.Value := CoverIndex - (WheelDelta div 120);
  Handled := True;
end;

procedure TForm2.DoCoverMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  TrackBar2.Value := Round(StrToFloat(IntToStr(TImage(Sender).Tag)));
end;

procedure TForm2.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  cvDestroyAllWindows;
end;

procedure TForm2.FormCreate(Sender: TObject);
var
  K: TAniCalculations;
begin
  FScalePicture := 1;
  with ImageViewer1 do
  begin
    DisableMouseWheel := True;
    MouseScaling := False;
    OnCalcContentBounds := HelpContentBounds;
    ShowScrollBars := False;
    K := TAniCalculations.Create(nil);
    K.Animation := True;
    K.Averaging := True;
// K.AutoShowing := True;
    K.TouchTracking := [ttVertical, ttHorizontal];
    AniCalculations.Assign(K);
  end;

  OpenDialog1.Filter := 'Comic Files|*.cbz;*.cbr;*.cb7|All Files|*.*';
end;

procedure TForm2.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
  Shift: TShiftState);
begin
  if Key = vkNext then
  begin

  end;
end;

procedure TForm2.HelpContentBounds(Sender: TObject; var CBounds: TRectF);
var
  H: TComponent;
  BR: TRectF;
  I: TImage;
  B: TRectangle;
begin
  for H in ImageViewer1 do
  begin
    if H is TImage then I := TImage(H);
    if H is TRectangle then B := TRectangle(H);
  end;

  I.Position.Point := PointF(0, 0);

  with THelpImageView(ImageViewer1) do
  begin
    I.BoundsRect := RectF(0, 0,
                      ImageViewer1.Bitmap.Width * FScalePicture,
                      ImageViewer1.Bitmap.Height * FScalePicture);
    if (Content <> nil) and (ContentLayout <> nil) then
    begin
      if I.Width < ContentLayout.Width then I.Position.X := (ContentLayout.Width - I.Width) * 0.5;
      if I.Height < ContentLayout.Height then I.Position.Y := (ContentLayout.Height - I.Height) * 0.5;
    end;

    CBounds := System.Types.UnionRect(RectF(0, 0, 0, 0), I.ParentedRect);

    if ContentLayout <> nil then
      BR := System.Types.UnionRect(CBounds, ContentLayout.ClipRect)
    else
      BR := I.BoundsRect;

    B.SetBounds(BR.Left, BR.Top, BR.Width, BR.Height);
    if CBounds.IsEmpty then
      CBounds := BR;

  end;
end;

procedure TForm2.ImageViewer1MouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; var Handled: Boolean);
begin
//  Exit;
  if WheelDelta > 0 then
  begin
    ScalePicture := ScalePicture + 0.1;
  end
  else
    ScalePicture := ScalePicture - 0.1;
end;

procedure TForm2.mnuOpenClick(Sender: TObject);
var
  LArchive: TJclDecompressArchive;
  I, J: Integer;
  LStream: TMemoryStream;
  LStream2: IStream;
  iRes: UInt64;
  Cover: TLayer3D;
  Layout: TLayout;
  Image: TImage;
  Effect: TReflectionEffect;
  L: TRectangle;
  LBmp: TBitmap;
  SL: TFileSorter;
begin
  if OpenDialog1.Execute then
  begin

    Coverflow.DeleteChildren;
    AniIndicator1.Visible := True;
    J := 0;

    case IndexStr(ExtractFileExt(OpenDialog1.FileName),
    ['.cbz', '.cbr', '.cb7']) of
    0:
      LArchive := TJclZipDecompressArchive.Create(OpenDialog1.FileName, 0, False);
    1:
      LArchive := TJclRarDecompressArchive.Create(OpenDialog1.FileName, 0, False);
    2:
      LArchive := TJcl7zDecompressArchive.Create(OpenDialog1.FileName, 0, False);
    end;
    try
      LArchive.ListFiles;

      // sort filenames
      SL := TFileSorter.Create;
      try
        for I := 0 to LArchive.ItemCount - 1 do
        begin
          // lets assign real index for extracting in right order from archive
          SL.AddObject(LArchive.Items[I].PackedName, TObject(I));
        end;
        SL.Sort;

        for I := 0 to SL.Count - 1 do
        begin
          if not LArchive.Items[Integer(SL.Objects[I])].Directory then
          begin
            LStream := TMemoryStream.Create;
            try
              LArchive.Items[Integer(SL.Objects[I])].Stream := LStream;
              LArchive.Items[Integer(SL.Objects[I])].OwnsStream := False;
              LArchive.Items[Integer(SL.Objects[I])].Selected := True;
              LArchive.ExtractSelected();
              // unselect to exclude it from next item selection
              LArchive.Items[Integer(SL.Objects[I])].Selected := False;

              case IndexStr(LArchive.Items[Integer(SL.Objects[I])].PackedExtension,
              ['.jpg', '.png', '.bmp', '.gif', '.webp', '.avif', '.heif', '.flif'])
               of
                0: // jpg
                begin
                  // create cover
                  Cover := TLayer3D.Create(Self);
                  Cover.Parent := Coverflow;

                  Cover.Projection := TProjection.Screen;
                  Cover.Width := Round(Coverflow.Height * 0.5);
                  Cover.Height := Round(Round(Coverflow.Height * 0.5) * 1.5);
                  Cover.ZWrite := True;
                  Cover.Fill.Color := Viewport3D1.Color;
                  Cover.Fill.Kind := TBrushKind.Solid;
                  Cover.Transparency := True;
                  Cover.OnLayerMouseDown := DoCoverMouseDown;
                  Cover.Tag := J;
                  Cover.Padding.Rect := TRectF.Create(0, 0, 0, 0);
                  Cover.Position.Y := Trunc((Coverflow.Height + Round(Coverflow.Height * 0.5)) / 2);
                  Cover.Cursor := crHandPoint;

                  if J = 0 then
                  begin
                    Cover.Position.X := Coverflow.Width / 2;
                  end
                  else
                  begin
                    Cover.Position.X := (I + 1) * (Round(Coverflow.Height * 0.5) / 3) + Coverflow.Width / 2;
                    Cover.Position.Z := Round(Coverflow.Height * 0.5) * 2;
                    Cover.RotationAngle.Y := 70;
                  end;

                  // Child
                  Layout := TLayout.Create(Self);
                  Layout.Parent := Cover;
                  Layout.Align := TAlignLayout.Top;
                  Layout.Height := Trunc(Cover.Height / 2); // original = 2
                  Layout.Padding.Rect := TRectF.Create(0, 0, 0, 0);
                  Layout.Cursor := crHandPoint;

                  // This rectangle is necessary to avoid blank lines on the image
                  L := TRectangle.Create(Self);
                  L.Parent := Layout;
                  L.Align := TAlignLayout.Top;
                  L.Height := Trunc(Cover.Height / 2);
                  L.Fill.Kind := TBrushKind.None;
                  L.Stroke.Color := Viewport3D1.Color;
                  L.Stroke.Kind := TBrushKind.None;

                  Image := TImage.Create(Self);
                  Image.Parent := Layout;
                  Image.Padding.Rect := TRectF.Create(0, 0, 0, 0);
                  Image.TagString := LArchive.Items[Integer(SL.Objects[I])].PackedName;

  //                LStream.Position := 0;
  //                TImageThread.Create(Image, LStream).Start;

                  LBmp := TBitmap.Create;
                  try
                    LStream.Position := 0;
                    LBmp.LoadFromStream(TStream(LStream));
                    Image.Width := LBmp.Width;
                    Image.Height := LBmp.Height;
                    Image.Bitmap := LBmp;
                  finally
                    LBmp.Free;
                  end;

                  Image.WrapMode := TImageWrapMode.Stretch;
                  Image.Align := TAlignLayout.Fit;
                  Image.HitTest := True;
                  //Image.TagString :=
                  Image.Cursor := crHandPoint;
                  //TImageThread.Create();
                  Image.OnMouseDown := DoCoverMouseDown;
                  Image.Tag := J;

                  Effect := TReflectionEffect.Create(Self);
                  Effect.Parent := Image;
                  Effect.Opacity := 0.6;

                  // Opacity animation
                  Cover.Opacity := 0.01;
                  Cover.AnimateFloat('Opacity', 1, 0.5);

                  // Load thumb
                  Cover.TagObject := Image;
                  Inc(J);

                  Application.ProcessMessages;

                end;
                1: // png
                begin

                end;
                2: // bmp
                begin

                end;
                3: // gif
                begin

                end;
                4: // webp
                begin

                end;
                5: // avif
                begin

                end;
                6: // heif
                begin

                end;
                7: // flif
                begin

                end;
              end;
            finally
              LStream.Free;
            end;
          end;
        end;

      finally
        SL.Free;
      end;
      CoverIndex := 0;
      AniIndicator1.Visible := False;
      TrackBar2.Max := Coverflow.ChildrenCount - 1;
      TrackBar2.Value := 1;
      TrackBar2.Value := 0;
      TrackBar2.Visible := True;
      TrackBar2.SetFocus;
    finally
      FreeAndNil(LArchive);
    end;
  end;
end;

procedure TForm2.MenuItem2Click(Sender: TObject);
var
  image: pIplImage;
  dst: pIplImage;
  img_gray: pIplImage;
  contours: pCvSeq;
  storage: pCvMemStorage;
  fn: ansistring;
begin
  image := nil;
  dst := nil;
  img_gray := nil;
  contours := nil;
  storage := nil;

  fn := ExtractFilePath(ParamStr(0))+'temp.png';
  ImageViewer1.Bitmap.SaveToFile(fn);
  Sleep(100);
  try
    image := cvLoadImage(PAnsiChar(fn), CV_LOAD_IMAGE_UNCHANGED);
    if Assigned(image) then
    begin
      img_gray := cvCreateImage(CvSize(image^.width, image^.height), IPL_DEPTH_8U, 1);
      dst := cvCreateImage(CvSize(image^.width, image^.height), IPL_DEPTH_8U, 1);
      storage := cvCreateMemStorage(0);
      cvCvtColor(image, img_gray, CV_BGR2GRAY);
      cvThreshold(img_gray, dst, 128, 255, CV_THRESH_BINARY_INV);
      contours := AllocMem(SizeOf(tcvseq));
      cvClearMemStorage(storage);
      cvFindContours(dst, storage, @contours, SizeOf(TCvContour), CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cvPoint(0, 0));
//      cvArcLength(nil, contours., True);
      cvDrawContours(image, contours, CV_RGB(100, 200, 0), CV_RGB(200, 100, 0), 2, -1, CV_AA, cvPoint(0, 0));
//      contours := cvConvexHull2(contours);
//      cvDrawContours(image, contours, CV_RGB(100, 200, 0), CV_RGB(200, 100, 0), 2, -1, CV_AA, cvPoint(0, 0));
//      cvShowImage('thres', dst);
//      cvShowImage('cont', image);
      cvSaveImage(PAnsiChar(fn), image);
      Sleep(100);
      ImageViewer2.Bitmap.LoadFromFile(fn);
//      cvWaitKey(0);

      cvReleaseImage(image);
      cvReleaseImage(dst);

    end;
  except
    on E: Exception do
      ShowMessageFmt('%s:%s', [E.ClassName, E.Message]);
  end;

end;

procedure TForm2.MenuItem3Click(Sender: TObject);
begin
  Close;
end;

procedure TForm2.SetCoverIndex(AIndex: Integer);
var
  I: Integer;
  Cover: TLayer3D;
  PercCoeff, Coeff: single;
begin
  if AniIndicator1.Visible or (Coverflow.ChildrenCount = 0) then
  begin
    TrackBar2.Value := CoverIndex;
    Abort;
  end;


  PercCoeff := 0.6;

  if AIndex <0 then AIndex := 0;
  if AIndex >= Coverflow.ChildrenCount then AIndex := Coverflow.ChildrenCount - 1;
  if AIndex <> CoverIndex then
  begin
    for I := 0 to Coverflow.ChildrenCount - 1 do
    begin
      Cover := TLayer3D(Coverflow.Children[I]);
      Cover.StopPropertyAnimation('Position.X');
      Cover.AnimateFloat('Position.X', Cover.Position.X + ((CoverIndex - AIndex) * (Round(Coverflow.Height * 0.5{factor}) div 3)), 0.5 {duration});
    end;

    I := CoverIndex;
    while I <> AIndex do
    begin
      Coeff := (0.1 + (Abs(AIndex - I) / Abs(AIndex - CoverIndex))) * (PercCoeff + 0.1);

      Cover := TLayer3D(Coverflow.Children[I]);
      Cover.StopPropertyAnimation('Position.X');
      Cover.StopPropertyAnimation('RotationAngle.Y');

      if CoverIndex > AIndex then
      begin
        Cover.AnimateFloat('RotationAngle.Y', 70, 0.5);
        if I = CoverIndex then
          Cover.AnimateFloat('Position.X', Cover.Position.X + (1 * (Round(Coverflow.Height * 0.5) div 3)), 0.5 * Coeff)
        else
          Cover.AnimateFloat('Position.X', Cover.Position.X + (2 * (Round(Coverflow.Height * 0.5) div 3)), 0.5 * Coeff);
      end
      else
      begin
        Cover.AnimateFloat('RotationAngle.Y', 70*-1, 0.5);
        if I = CoverIndex then
          Cover.AnimateFloat('Position.X', Cover.Position.X - (1 * (Round(Coverflow.Height * 0.5) div 3)), 0.5 * Coeff)
        else
          Cover.AnimateFloat('Position.X', Cover.Position.X - (2 * (Round(Coverflow.Height * 0.5) div 3)), 0.5 * Coeff);
      end;
      Cover.AnimateFloat('Position.Z', Round(Coverflow.Height * 0.5) * 2, 0.5);
      if AIndex > CoverIndex then
        Inc(I)
      else
        Dec(I);
    end;

    Cover := TLayer3D(Coverflow.Children[AIndex]);

    Cover.StopPropertyAnimation('Position.X');
    Cover.StopPropertyAnimation('Position.Z');

    Cover.AnimateFloat('RotationAngle.Y', 0, 0.5);
    Cover.AnimateFloat('Position.Z', 0, 0.5);
    if CoverIndex > AIndex then
      Cover.AnimateFloat('Position.X', Cover.Position.X + (1 * (Round(Coverflow.Height * 0.5) div 3)), 0.5)
    else
      Cover.AnimateFloat('Position.X', Cover.Position.X - (1 * (Round(Coverflow.Height * 0.5) div 3)), 0.5);

    ImageViewer1.Bitmap := (Cover.TagObject as TImage).Bitmap;
    Caption := 'CDisplayAI v1.0 - ' + (Cover.TagObject as TImage).TagString;
    CoverIndex := AIndex;

  end;

end;

procedure TForm2.SetScalePicture(const Value: Single);
var
  R: IAlignRoot;
  S: Single;
  P, E: TPointF;
begin
  if Assigned(ImageViewer1) and not ImageViewer1.Bitmap.IsEmpty then
  begin
    if FScalePicture <> Value then
    begin
      S := FScalePicture;
      FScalePicture := Value;
      if FScalePicture < 0.1 then
      begin
        FScalePicture := 0.1;
//        ImageViewer1.AniCalculations.Animation := False;
      end;
      if FScalePicture > 10 then
        FScalePicture := 10;
      S := FScalePicture / S;

      ImageViewer1.AniCalculations.Animation := False;

      ImageViewer1.BeginUpdate;

      P := PointF(ImageViewer1.ClientWidth, ImageViewer1.ClientHeight) * 0.5;
      E := ImageViewer1.ViewportPosition;
      E := E + P;

      ImageViewer1.InvalidateContentSize;
      R := ImageViewer1;
      R.Realign;

      ImageViewer1.ViewportPosition := (E * S) - P;

      ImageViewer1.EndUpdate;

      ImageViewer1.AniCalculations.Animation := True;

      ImageViewer1.Repaint;


    end;
  end;

  FScalePicture := Value;

end;

procedure TForm2.TrackBar1Tracking(Sender: TObject);
begin
  ScalePicture := TrackBar1.Value;
end;

procedure TForm2.TrackBar2Change(Sender: TObject);
begin
  SetCoverIndex(Round(TrackBar2.Value));
end;

{ TImageThread }

constructor TImageThread.Create(const AImage: TImage; const AStream: TMemoryStream);
begin
  inherited Create(True);
  FFilename := AStream;
  FImage := AImage;
//  Priority := tpIdle;
  FreeOnTerminate := True;
end;

destructor TImageThread.Destroy;
begin
  inherited;
end;

procedure TImageThread.Execute;
var
  LBmp: TBitmap;
begin
//  inherited;
//  Sleep(Random(300));
  FTempBitmap := TBitmap.Create(0, 0);
  //FTempBitmap.LoadThumbnailFromFile(FFilename, FImage.Width, FImage.Height, False);
  LBmp := TBitmap.Create;
  try
    FFilename.Position := 0;
    LBmp.LoadFromStream(TStream(FFilename));
    FImage.Width := LBmp.Width;
    FImage.Height := LBmp.Height;
  finally
    LBmp.Free;
  end;
  Synchronize(Finished);
end;

procedure TImageThread.Finished;
begin
  FImage.Bitmap.Assign(FTempBitmap);
  FTempBitmap.Free;
end;

{ TFileSorter }

function TFileSorter.CompareStrings(const S1, S2: string): Integer;
begin
  Result := StrCmpLogicalW(PChar(S1), PChar(S2));
end;


end.
