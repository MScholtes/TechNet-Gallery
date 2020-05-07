// Markus Scholtes, 2017
// WPF "all in one file" demo
// no Visual Studio or MSBuild is required for compiling
// Requirements: .Net 3.5x and/or .Net 4.x

// Clock program: timer, transparent window, diverse event handler, setting of the color with commandline parameters


/* Compile with:
C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe /target:winexe "06 Clock.cs" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationframework.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\windowsbase.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationcore.dll"
or
C:\Windows\Microsoft.NET\Framework\v3.5\csc.exe /target:winexe "06 Clock.cs" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationframework.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\windowsbase.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationcore.dll"
(see https://msdn.microsoft.com/de-de/library/aa970678(v=vs.85).aspx)
*/

using System;
using System.Xml;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Markup;

public class Programm
{
	// the WPF objects that have to be generated in code
	private static TextBlock objTime, objSeconds, objDayNumber, objMonth, objDayText, objYear;

	// timer for the clock
	private static System.Windows.Threading.DispatcherTimer objTimer = new System.Windows.Threading.DispatcherTimer();

	// since inheritance of Window does not work, the eventhandler have to be static methods and added after generation of the Window object

	// eventhandler fot timer: fill the fields of the clock with the actual date and time
	private static void Timer_RefreshClock(object sender, EventArgs e)
	{
		DateTime objNow = DateTime.Now;
		objTime.Text = objNow.ToString("hh:mm").TrimStart('0');
		objSeconds.Text = objNow.ToString("ss");
		objDayNumber.Text = objNow.ToString("dd");
		objMonth.Text = objNow.ToString("MMMM");
		objDayText.Text = objNow.ToString("dddd");
		objYear.Text = objNow.ToString("yyyy");
	}

	// this handler is called while building the window before displaying it
	private static void Window_SourceInitialized(object sender, EventArgs e)
	{
		// set timer interval to one second
		objTimer.Interval = new TimeSpan(0, 0, 1);
		// define routine that is called when timer interval is reached
		objTimer.Tick += Timer_RefreshClock;
		// start timer
		objTimer.Start();
		if (!objTimer.IsEnabled)
		{	// show message on error
			MessageBox.Show("Cannot start timer, clock does not work!", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
		}
	}

	// this handler is called when the window is closed
	private static void Window_Closed(object sender, EventArgs e)
	{
		// stop timer
		objTimer.Stop();
	}

	// right mouseclick
	private static void Window_MouseRightButtonUp(object sender, MouseButtonEventArgs e)
	{
		// event is handled now
		e.Handled = true;
		// the sender object is the object that generated the event
		((Window)sender).Close();
	}

	// left mouseclick
	private static void Window_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
	{
		// the sender object is the object that generated the event
		// allow "move window" per drag with left mouse button
		((Window)sender).DragMove();
	}

	// keyboard is pressed
	private static void Window_KeyDown(object sender, KeyEventArgs e)
	{
		if (System.Windows.Input.Keyboard.IsKeyDown(System.Windows.Input.Key.LeftAlt) && System.Windows.Input.Keyboard.IsKeyDown(System.Windows.Input.Key.X))
		{ // Alt-X pressed
			// event is handled now
			e.Handled = true;
			// the sender object is the object that generated the event
			((Window)sender).Close();
		}
	}

	// handler for change of size of the textfield (correct position of the "second field")
	private static void Time_SizeChanged(object sender, SizeChangedEventArgs e)
	{
	  if (objTime.Text.Length == 4)
	  {
  	  objSeconds.Margin = new Thickness(133, 0, 86, 0);
  	}
  	else
  	{
    	objSeconds.Margin = new Thickness(172, 0, 48, 0);
  	}
	}

	// handler for change of size of the "month field" (correct position of the "year field")
	private static void Month_SizeChanged(object sender, SizeChangedEventArgs e)
	{
 	  objYear.Margin = new Thickness(Math.Max(objDayText.ActualWidth, objMonth.ActualWidth) + 62, objYear.Margin.Top, objYear.Margin.Right, objYear.Margin.Bottom);
	}

	// WPF requires STA model. Since C# uses MTA as default, the following compiler directive is required
	[STAThread]
	public static void Main(string[] Parameter)
	{

		// XAML string that defines the WPF controls
		string strXAML = @"
<Window
    xmlns=""http://schemas.microsoft.com/winfx/2006/xaml/presentation""
    xmlns:x=""http://schemas.microsoft.com/winfx/2006/xaml""
    WindowStyle = ""None"" WindowStartupLocation = ""CenterScreen"" SizeToContent = ""WidthAndHeight"" ShowInTaskbar = ""False""
    ResizeMode = ""NoResize"" Title = ""Clock"" AllowsTransparency = ""True"" Background = ""Transparent"" Opacity = ""1"" Topmost = ""True"">
  <Grid x:Name = ""Grid"" Background = ""Transparent"">
    <TextBlock x:Name = ""Time"" FontSize = ""72"" Foreground = ""TIMECOLOR"" VerticalAlignment=""Top""
    HorizontalAlignment=""Left"" Margin=""0,-26,0,0"">
        <TextBlock.Effect>
          <DropShadowEffect Color = ""SHADOWCOLOR"" ShadowDepth = ""3"" BlurRadius = ""5"" />
        </TextBlock.Effect>
    </TextBlock>
    <TextBlock x:Name = ""Seconds"" FontSize = ""25"" Foreground = ""TIMECOLOR"" Margin = ""172,0,48,0""
    HorizontalAlignment=""Left"">
        <TextBlock.Effect>
          <DropShadowEffect Color = ""SHADOWCOLOR"" ShadowDepth = ""3"" BlurRadius = ""2"" />
        </TextBlock.Effect>
    </TextBlock>
    <TextBlock x:Name = ""DayNumber"" FontSize = ""38"" Foreground = ""DATECOLOR"" Margin=""5,42,0,0""
    HorizontalAlignment=""Left"">
        <TextBlock.Effect>
          <DropShadowEffect Color = ""SHADOWCOLOR"" ShadowDepth = ""3"" BlurRadius = ""2"" />
        </TextBlock.Effect>
    </TextBlock>
    <TextBlock x:Name = ""Month"" FontSize = ""20"" Foreground = ""DATECOLOR"" Margin=""54,48,0,0""
    HorizontalAlignment=""Left"">
        <TextBlock.Effect>
          <DropShadowEffect Color = ""SHADOWCOLOR"" ShadowDepth = ""3"" BlurRadius = ""2"" />
        </TextBlock.Effect>
    </TextBlock>
    <TextBlock x:Name = ""DayText"" FontSize = ""15"" Foreground = ""DATECOLOR"" Margin=""54,68,0,0""
    HorizontalAlignment=""Left"">
        <TextBlock.Effect>
          <DropShadowEffect Color = ""SHADOWCOLOR"" ShadowDepth = ""3"" BlurRadius = ""2"" />
        </TextBlock.Effect>
    </TextBlock>
    <TextBlock x:Name = ""Year"" FontSize = ""38"" Foreground = ""DATECOLOR"" Margin=""112,42,0,0""
    HorizontalAlignment=""Left"">
        <TextBlock.Effect>
          <DropShadowEffect Color = ""SHADOWCOLOR"" ShadowDepth = ""3"" BlurRadius = ""2"" />
        </TextBlock.Effect>
    </TextBlock>
  </Grid>
</Window>";

		// interpret command line parameters
		if (Parameter.Length > 0)
		{ // color for time given, replace the placeholder in XML string
			strXAML = strXAML.Replace("TIMECOLOR", Parameter[0]);
		}
		else
		{ // no color for time given, replace the placeholder in XML string with "White"
			strXAML = strXAML.Replace("TIMECOLOR", "White");
		}

		if (Parameter.Length > 1)
		{ // color for date given, replace the placeholder in XML string
			strXAML = strXAML.Replace("DATECOLOR", Parameter[1]);
		}
		else
		{ // no color for date given, replace the placeholder in XML string with "White"
			strXAML = strXAML.Replace("DATECOLOR", "White");
		}

		if (Parameter.Length > 2)
		{ // color for shadow given, replace the placeholder in XML string
			strXAML = strXAML.Replace("SHADOWCOLOR", Parameter[2]);
		}
		else
		{ // no color for shadow given, replace the placeholder in XML string with "Black"
			strXAML = strXAML.Replace("SHADOWCOLOR", "Black");
		}

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

		// search the object of the textblocks
		objTime = (TextBlock)objWindow.FindName("Time");
		objSeconds = (TextBlock)objWindow.FindName("Seconds");
		objDayNumber = (TextBlock)objWindow.FindName("DayNumber");
		objMonth = (TextBlock)objWindow.FindName("Month");
		objDayText = (TextBlock)objWindow.FindName("DayText");
		objYear = (TextBlock)objWindow.FindName("Year");

		// add eventhandler (the last parameter false means, that the handler is not called, when an event is already handled)
		objWindow.AddHandler(FrameworkElement.MouseLeftButtonDownEvent, new MouseButtonEventHandler(Window_MouseLeftButtonDown), false);
		objWindow.AddHandler(FrameworkElement.MouseRightButtonUpEvent, new MouseButtonEventHandler(Window_MouseRightButtonUp), false);
		objWindow.AddHandler(FrameworkElement.KeyDownEvent, new KeyEventHandler(Window_KeyDown), false);
		objWindow.SourceInitialized += Window_SourceInitialized;
		objWindow.Closed += Window_Closed;
		objTime.SizeChanged += Time_SizeChanged;
		objMonth.SizeChanged += Month_SizeChanged;

		// initial set of the clock values by calling eventhandler of the timer
		Timer_RefreshClock(null, null);

		// and show WPF window
		objWindow.ShowDialog();
	}
}
