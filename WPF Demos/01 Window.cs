// Markus Scholtes, 2017
// WPF "all in one file" demo
// no Visual Studio or MSBuild is required for compiling
// Requirements: .Net 3.5x and/or .Net 4.x

// Minimal WPF program: a windows with text


/* Compile with:
C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe /target:winexe "01 Window.cs" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationframework.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\windowsbase.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationcore.dll"
or
C:\Windows\Microsoft.NET\Framework\v3.5\csc.exe /target:winexe "01 Window.cs" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationframework.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\windowsbase.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationcore.dll"
(see https://msdn.microsoft.com/de-de/library/aa970678(v=vs.85).aspx)
*/

using System;
using System.Xml;
using System.Windows;
using System.Windows.Markup;

public class Programm
{
	// WPF requires STA model. Since C# uses MTA as default, the following compiler directive is required
	[STAThread]
	public static void Main()
	{
		// XAML string that defines the WPF controls
		string strXAML = @"
<Window
	xmlns=""http://schemas.microsoft.com/winfx/2006/xaml/presentation""
	xmlns:x=""http://schemas.microsoft.com/winfx/2006/xaml""
	x:Name=""Window"" Title=""Test program for Windows Presentation Framework"" WindowStartupLocation = ""CenterScreen""
	Width = ""800"" Height = ""600"" ShowInTaskbar = ""True"">
	<TextBlock TextAlignment=""Center"" VerticalAlignment=""Center"" Foreground=""Black"" FontSize=""40"" HorizontalAlignment=""Center"">
	  <TextBlock.Effect><DropShadowEffect ShadowDepth=""4"" Color=""DarkGray"" BlurRadius=""4""/></TextBlock.Effect>
		Test program for<LineBreak/><LineBreak/>Windows Presentation Framework
	</TextBlock>
</Window>";

		// prepare XML document
		XmlDocument XAML = new XmlDocument();
		// read XAML string
		XAML.LoadXml(strXAML);
		// and convert to XML
		XmlNodeReader XMLReader = new XmlNodeReader(XAML);
		// generate WPF object tree
		Window objWindow;
		try
		{	// set XAML root object
			objWindow = (Window)XamlReader.Load(XMLReader);
		}
		catch
		{ // XamlReader generates an exception on error in XAML definition
			MessageBox.Show("Error while creating the WPF controls out of the XAML description", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
			return;
		}

		// and show WPF window
		objWindow.ShowDialog();
	}
}
