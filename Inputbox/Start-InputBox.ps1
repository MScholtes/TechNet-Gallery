<#
.SYNOPSIS
Defines a C# class InputBox and imports it to powershell
.DESCRIPTION
Defines a C# class InputBox and imports it to powershell.
You can then call [InputBox]::Show(...) to present a Winforms inputbox in powershell.
The inputbox resizes automaticly to fit the GUI controls. Plain text or password text for input is supported.
.NOTES
Name: Start-InputBox.ps1
Author: Markus Scholtes
Creation date: 03/20/2016
.EXAMPLE
$Value = "default value"
[InputBox]::Show([ref]$Value, "Title of inputbox", "Type in a text please:")


Reads text and stores it to $Value. $Value has to be defined before.
.EXAMPLE
New-Variable PASS -Force
if ([InputBox]::Show([ref]$PASS, "", "Need password:", $TRUE) -eq "OK")
{ "Password stored" } else { "Cancel" }


Reads password and stores it to $PASS. $PASS has to be defined before.
.EXAMPLE
New-Variable InputVal -Force
[InputBox]::Show([ref]$InputVal)


Reads text and stores it to $InputVal. The inputbox has default title and default prompt.
#>

$CSSource = @"
using System.Windows.Forms;
using System.Drawing;

public class InputBox
{
	public static DialogResult Show(ref string sValue, string sTitle, string sPrompt, bool bSecure)
	{
	  // Generate controls
	  Form form = new Form();
	  Label label = new Label();
	  TextBox textBox = new TextBox();
	  Button buttonOk = new Button();
	  Button buttonCancel = new Button();

	  // Sizes and positions are defined according to the label
	  // This control has to be finished first
		if (string.IsNullOrEmpty(sPrompt))
		{
			if (bSecure)
				label.Text = "Type in password: ";
			else
				label.Text = "Type in text:     ";
		}
		else
		  label.Text = sPrompt;
	  label.Location = new Point(9, 19);
	  label.AutoSize = true;
	  // Size of the label is defined not before Add()
	  form.Controls.Add(label);

	  // Generate textbox
		if (bSecure) textBox.UseSystemPasswordChar = true;
	  textBox.Text = sValue;
	  textBox.SetBounds(12, label.Bottom, label.Right - 12, 20);

	  // Generate buttons
	  buttonOk.Text = "OK";
	  buttonCancel.Text = "Cancel";
	  buttonOk.DialogResult = DialogResult.OK;
	  buttonCancel.DialogResult = DialogResult.Cancel;
	  buttonOk.SetBounds(System.Math.Max(12, label.Right - 158), label.Bottom + 36, 75, 23);
	  buttonCancel.SetBounds(System.Math.Max(93, label.Right - 77), label.Bottom + 36, 75, 23);

	  // Configure form
		if (string.IsNullOrEmpty(sTitle))
			form.Text = "Powershell";
		else
			form.Text = sTitle;
		form.ClientSize = new System.Drawing.Size(System.Math.Max(178, label.Right + 10), label.Bottom + 71);
	  form.Controls.AddRange(new Control[] { textBox, buttonOk, buttonCancel });
	  form.FormBorderStyle = FormBorderStyle.FixedDialog;
	  form.StartPosition = FormStartPosition.CenterScreen;
	  form.MinimizeBox = false;
	  form.MaximizeBox = false;
	  form.AcceptButton = buttonOk;
	  form.CancelButton = buttonCancel;

	  // Show form and compute results
	  DialogResult dialogResult = form.ShowDialog();
	  sValue = textBox.Text;
	  return dialogResult;
	}

	// Optional parameters are not allowed in Powershell V2.0, so an override for 
	// each desired parameter signature is defined

	// Inputbox with text field (no password field)
	public static DialogResult Show(ref string sValue, string sTitle, string sPrompt)
	{
		return Show(ref sValue, sTitle, sPrompt, false);
	}

	// Inputbox with text field and standard prompt (no password field)
	public static DialogResult Show(ref string sValue, string sTitle)
	{
		return Show(ref sValue, sTitle, "", false);
	}

	// Inputbox with text field and standard prompt and standard title (no password field)
	public static DialogResult Show(ref string sValue)
	{
		return Show(ref sValue, "", "", false);
	}
}
"@

Add-Type -TypeDefinition $CSSource -ReferencedAssemblies ("System.Windows.Forms", "System.Drawing") -Language CSharp
