program FieldReport;

uses
  System.StartUpCopy,
  FMX.Forms,
  Form.Main in 'Form.Main.pas' {HeaderFooterForm},
  Frame.ReportItem in 'Frame.ReportItem.pas' {ReportItemFrame: TFrame},
  Settings in 'Settings.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(THeaderFooterForm, HeaderFooterForm);
  Application.Run;
end.
