unit Form.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, System.Actions, FMX.ActnList, FMX.StdActns,
  FMX.MediaLibrary.Actions, FMX.Objects, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo;

type
  THeaderFooterForm = class(TForm)
    Header: TToolBar;
    Footer: TToolBar;
    HeaderLabel: TLabel;
    ActionList1: TActionList;
    ActionTakePhotoForReport: TTakePhotoFromCameraAction;
    PreviewImage: TImage;
    BtnTakePicture: TSpeedButton;
    BtnSaveReport: TSpeedButton;
    BtnDiscardReport: TSpeedButton;
    ComposePanel: TPanel;
    NotesEdit: TMemo;
    ActionDiscardReport: TAction;
    ActionSaveReport: TAction;
    procedure ActionTakePhotoForReportDidFinishTaking(Image: TBitmap);
    procedure FormCreate(Sender: TObject);
    procedure FormVirtualKeyboardShown(Sender: TObject;
      KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormVirtualKeyboardHidden(Sender: TObject;
      KeyboardVisible: Boolean; const Bounds: TRect);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  HeaderFooterForm: THeaderFooterForm;

implementation

{$R *.fmx}

procedure THeaderFooterForm.FormCreate(Sender: TObject);
begin
  ComposePanel.Visible := False;
end;

procedure THeaderFooterForm.FormVirtualKeyboardHidden(Sender: TObject;
  KeyboardVisible: Boolean; const Bounds: TRect);
begin
  ComposePanel.Margins.Bottom := 0;
end;

procedure THeaderFooterForm.FormVirtualKeyboardShown(Sender: TObject;
  KeyboardVisible: Boolean; const Bounds: TRect);
begin
  ComposePanel.Margins.Bottom := Bounds.Height - Footer.Height;
end;

procedure THeaderFooterForm.ActionTakePhotoForReportDidFinishTaking(
  Image: TBitmap);
begin
  PreviewImage.Bitmap.Assign(Image);
  NotesEdit.Lines.Clear;
  ComposePanel.Visible := True;
  NotesEdit.SetFocus;
end;

end.
