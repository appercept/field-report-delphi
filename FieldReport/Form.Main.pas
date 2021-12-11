unit Form.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, System.Actions, FMX.ActnList, FMX.StdActns,
  FMX.MediaLibrary.Actions, FMX.Objects, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo,
  FMX.Layouts;

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
    ReportContainer: TVertScrollBox;
    procedure ActionTakePhotoForReportDidFinishTaking(Image: TBitmap);
    procedure FormCreate(Sender: TObject);
    procedure FormVirtualKeyboardShown(Sender: TObject;
      KeyboardVisible: Boolean; const Bounds: TRect);
    procedure FormVirtualKeyboardHidden(Sender: TObject;
      KeyboardVisible: Boolean; const Bounds: TRect);
    procedure ActionSaveReportExecute(Sender: TObject);
    procedure ActionDiscardReportExecute(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  HeaderFooterForm: THeaderFooterForm;

implementation

{$R *.fmx}

uses Frame.ReportItem;

procedure THeaderFooterForm.FormCreate(Sender: TObject);
begin
  ComposePanel.Visible := False;
  ActionDiscardReport.Enabled := False;
  ActionSaveReport.Enabled := False;
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

procedure THeaderFooterForm.ActionDiscardReportExecute(Sender: TObject);
begin
  ComposePanel.Visible := False;
  ActionDiscardReport.Enabled := False;
  ActionSaveReport.Enabled := False;
end;

procedure THeaderFooterForm.ActionSaveReportExecute(Sender: TObject);
var
  LReportItem: TReportItemFrame;
begin
  ComposePanel.Visible := False;
  LReportItem := TReportItemFrame.Create(ReportContainer.Content);
  LReportItem.Name := Format('ReportItem%d', [ReportContainer.Content.ChildrenCount + 1]);
  LReportItem.Parent := ReportContainer.Content;
  LReportItem.Position.Y := LReportItem.Height * ReportContainer.Content.ChildrenCount + 1;
  LReportItem.UploadReport(PreviewImage.Bitmap, NotesEdit.Text);
  ActionDiscardReport.Execute;
end;

procedure THeaderFooterForm.ActionTakePhotoForReportDidFinishTaking(
  Image: TBitmap);
begin
  PreviewImage.Bitmap.Assign(Image);
  NotesEdit.Lines.Clear;
  ComposePanel.Visible := True;
  NotesEdit.SetFocus;
  ActionDiscardReport.Enabled := True;
  ActionSaveReport.Enabled := True;
end;

end.
