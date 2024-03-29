unit main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.ExtCtrls, FMX.Menus, FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls,
  System.UIConsts, FMX.Effects, FMX.Types3D, ShlWapi, System.Generics.Collections,
  System.Math.Vectors, FMX.Controls3D, FMX.Layers3D, FMX.Viewport3D,
  System.Generics.Defaults,
  JclCompression, JclStrings, w2xconvunit, ocv.highgui_c, ocv.core_c,
  ocv.core.types_c, ocv.imgproc_c, ocv.imgproc.types_c, StrUtils, Winapi.Activex,
  Vcl.Imaging.PngImage, Vcl.Imaging.JPEG,
  OtlParallel, OtlEventMonitor, FMX.ListBox;

type

  TPageDetails = class
  private
    Frame: TCvRect;
  public
    constructor Create(const rect: TCvRect);
    destructor Destroy; override;
  end;

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
    AniIndicator2: TAniIndicator;
    OmniEventMonitor1: TOmniEventMonitor;
    StatusBar1: TStatusBar;
    Label1: TLabel;
    ListBox1: TListBox;
    Selection1: TSelection;
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
    procedure ImageViewer1ViewportPositionChange(Sender: TObject;
      const OldViewportPosition, NewViewportPosition: TPointF;
      const ContentSizeChanged: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure ListBox1Change(Sender: TObject);
  private
  { Private declarations }
    CoverIndex: Integer;

    { Page details}
    PageDetails: TObjectList<TPageDetails>;

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

  PageDetails := TObjectList<TPageDetails>.Create;
end;

procedure TForm2.FormDestroy(Sender: TObject);
begin
  PageDetails.Free;
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

procedure TForm2.ImageViewer1ViewportPositionChange(Sender: TObject;
  const OldViewportPosition, NewViewportPosition: TPointF;
  const ContentSizeChanged: Boolean);
begin

  Label1.Text := 'Position: ' + newviewportposition.X.ToString+
                   ':' + newviewportposition.Y.ToString +
                   ' ' + ImageViewer1.ContentBounds.Width.ToString;
end;

procedure TForm2.ListBox1Change(Sender: TObject);
var
  r: TCvRect;
begin
  if (ListBox1.Items.Count > 0) and (ListBox1.ItemIndex >= 0) then
  begin
    r := PageDetails.Items[ListBox1.ItemIndex].Frame;

    //ImageViewer1.Bitmap.FlipHorizontal;
    Selection1.Position.X := r.x;
    Selection1.Position.Y := r.y;
    Selection1.Width := r.width;
    Selection1.Height := r.height;

    ImageViewer1.ViewportPosition :=PointF(r.x,r.y);

//    ImageViewer1.Scale.X := ImageViewer1.Bitmap.Width / r.width;
//    ImageViewer1.Scale.Y := ImageViewer1.Bitmap.Height/ r.height;
  end;
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
  ImageFound: Boolean;
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

              Image := TImage.Create(Self);

              LStream.Position := 0;
              case IndexStr(LArchive.Items[Integer(SL.Objects[I])].PackedExtension,
              ['.jpg', '.png', '.bmp', '.gif', '.webp', '.avif', '.heif', '.flif'])
               of
                0, 1, 2, 3: // jpg, png, bmp and gif are supported by FMX TBitmap
                begin
                  ImageFound := True;
                  LBmp := TBitmap.Create;
                  try
                    LBmp.LoadFromStream(TStream(LStream));
                    Image.Width := LBmp.Width;
                    Image.Height := LBmp.Height;
                    Image.Bitmap := LBmp;
                    ImageViewer1.Bitmap := LBmp;
                  finally
                    LBmp.Free;
                  end;
                end;
                4: // webp
                begin
                  ImageFound := False;
                end;
                5: // avif
                begin
                  ImageFound := False;
                end;
                6: // heif
                begin
                  ImageFound := False;
                end;
                7: // flif
                begin
                  ImageFound := False;
                end;
                else
                begin
                  ImageFound := False;
                end;
              end;

              if ImageFound then
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

                Image.Parent := Layout;
                Image.Padding.Rect := TRectF.Create(0, 0, 0, 0);
                Image.TagString := LArchive.Items[Integer(SL.Objects[I])].PackedName;

  //                LStream.Position := 0;
  //                TImageThread.Create(Image, LStream).Start;



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
              end
              else
                Image.Free; // remove it since it was not an image

              Application.ProcessMessages;
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
  mat: PCvMat;
  png: TPngImage;
  ab: array of byte;
  stream: TMemoryStream;
  N: Integer;
  contoursCont: Integer;
begin
  if AniIndicator2.Visible then Abort;

  AniIndicator2.Enabled := True;
  AniIndicator2.Visible := True;
  AniIndicator2.Align := TAlignLayout.HorzCenter;
  ImageViewer2.Enabled := False;

  image := nil;
  dst := nil;
  img_gray := nil;
  contours := nil;
  storage := nil;

//      Application.ProcessMessages;

//        fn := ExtractFilePath(ParamStr(0))+'temp.png';
//        ImageViewer1.Bitmap.SaveToFile(fn);

  stream := TMemoryStream.Create;
  try
    ImageViewer1.Bitmap.SaveToStream(stream);

//    png := TPngImage.Create;
//    stream.Position := 0;
//    png.LoadFromStream(stream);
////    png.SaveToFile(fn);
//    stream.Position := 0;
//    png.SaveToStream(stream);
////    png.Free;

    // copy to array of bytes
    stream.Position := 0;
    SetLength(ab, stream.Size);
    stream.Read(ab[0], stream.Size);
//    stream.Free;

    Sleep(100);
    try
//      stream.Position := 0;
      mat := cvCreateMat(1, Length(ab), CV_8UC1);
//      mat := cvInitMatHeader(@mat, 1, Length(ab), CV_8U, @ab[0]);
//      cvCreateMatHeader(1, Length(ab), CV_8U);
      mat.data.ptr := @ab[0];
      image := cvDecodeImage(mat, CV_LOAD_IMAGE_UNCHANGED);
      Sleep(100);

//      image := cvLoadImage(PAnsiChar(fn), CV_LOAD_IMAGE_UNCHANGED);
      if Assigned(image) then
      begin
//        cvShowImage('cont', image);
        img_gray := cvCreateImage(CvSize(image^.width, image^.height), IPL_DEPTH_8U, 1);
        dst := cvCreateImage(CvSize(image^.width, image^.height), IPL_DEPTH_8U, 1);
        storage := cvCreateMemStorage(0);
        cvCvtColor(image, img_gray, CV_BGR2GRAY);
        cvThreshold(img_gray, dst, 128, 255, CV_THRESH_BINARY_INV);
        //contours := AllocMem(SizeOf(tcvseq));
        cvClearMemStorage(storage);
        cvSmooth(dst, dst, CV_GAUSSIAN, 9, 9); //to improve speed in contour detection
        contours := nil;
        contoursCont :=  cvFindContours(dst, storage, @contours, SizeOf(TCvContour), CV_RETR_EXTERNAL, CV_CHAIN_APPROX_SIMPLE, cvPoint(0, 0));

        //if (contoursCont > 0) and (contoursCont < 50) then
        begin
          PageDetails.Clear;
          while Assigned(contours) do
            if CV_IS_SEQ_CLOSED(contours) then
            begin
              //contours := cvConvexHull2(contours);
              var rect := cvBoundingRect(contours);
              if rect.width > 100  then
              begin
                PageDetails.Add(TPageDetails.Create(rect));
                cvRectangle(image, cvPoint(rect.x, rect.y),
                  cvPoint(rect.x + rect.width, rect.y + rect.height),
                    CV_RGB(-1,250,0), 3);
                cvDrawContours(image, contours,
                    CV_RGB(255, 0, 0),
                    CV_RGB(255, 0, 0), 2, 2, CV_AA, cvPoint(0, 0));
              end;
              contours := contours^.h_next;
            end;
            // sort frames using manga or comic orientation
            PageDetails.Sort(
              TComparer<TPageDetails>.Construct(
                function(const A, B: TPageDetails): Integer
                begin
                  if (A.Frame.y * image.width + A.Frame.x < B.Frame.y * image.width + B.Frame.x)
                  then
                  begin
                    // consider a frame in the left side with its y position a little bit
                    // below the right frame (less the 3rd height) as prior since it
                    // might be a scanning issue (angle)
                    if (B.Frame.x + B.Frame.width < A.Frame.x)
                    and (B.Frame.y < (A.Frame.y + A.Frame.height/3))
                    then
                      Result := 1
                    else
                      Result := -1
                  end
                  else if A.Frame.y = B.Frame.y then
                    Result := 0
                  else
                  begin
                    Result := 1;
                  end;
                end
              )
            );
            ListBox1.Clear;
            for N := 0 to (PageDetails.Count - 1) do
            begin
              ListBox1.Items.Add('x: '+
                PageDetails.Items[N].Frame.x.ToString + ' y: ' +
                PageDetails.Items[N].Frame.y.ToString + ' width: '+
                PageDetails.Items[N].Frame.width.ToString + ' height: '+
                PageDetails.Items[N].Frame.height.ToString
              );
            end;
        end;

  //      cvArcLength(nil, contours., True);
  //      contours := cvConvexHull2(contours);
  //      cvDrawContours(image, contours, CV_RGB(100, 200, 0), CV_RGB(200, 100, 0), 2, -1, CV_AA, cvPoint(0, 0));
  //        cvShowImage('thres', dst);
  //        cvShowImage('cont', image);
        mat := cvEncodeImage('.png', image);
        stream.Position := 0;
        stream.Write(mat.data.ptr[0], mat.cols);
  //        cvSaveImage(PAnsiChar(fn), image);
        Sleep(100);
  //        ImageViewer2.Bitmap.LoadFromFile(fn);
        stream.Position := 0;
        ImageViewer2.Bitmap.Clear(0);
        ImageViewer2.Bitmap.LoadFromStream(stream);

        cvReleaseImage(image);
        cvReleaseImage(dst);

      end;
    except
  //          on E: Exception do
  //            ShowMessageFmt('%s:%s', [E.ClassName, E.Message]);
    end;

  finally
    SetLength(ab, 0);
    stream.Free;
  end;

  AniIndicator2.Enabled := False;
  AniIndicator2.Visible := False;
  ImageViewer2.Enabled := True;

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


{ TPageDetails }

constructor TPageDetails.Create(const rect: TCvRect);
begin
  Frame := rect;
end;

destructor TPageDetails.Destroy;
begin

  inherited;
end;

end.
