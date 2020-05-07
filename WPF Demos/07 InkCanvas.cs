// Markus Scholtes, 2017
// WPF "all in one file" demo
// no Visual Studio or MSBuild is required for compiling
// Requirements: .Net 3.5x and/or .Net 4.x

// Demo program: Ink window


/* Compile with:
C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe /target:winexe "07 InkCanvas.cs" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationframework.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\windowsbase.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationcore.dll"
or
C:\Windows\Microsoft.NET\Framework\v3.5\csc.exe /target:winexe "07 InkCanvas.cs" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationframework.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\windowsbase.dll" /r:"C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\presentationcore.dll"
(see https://msdn.microsoft.com/de-de/library/aa970678(v=vs.85).aspx)
*/

using System;
using System.IO;
using System.Xml;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Ink;
using System.Windows.Input;
using System.Windows.Markup;
using System.Windows.Media;

public class Programm
{
  // Store for brush sizes
  private static double StoreHighLightSizeWidth = -1.0, StoreHighLightSizeHeight, StoreInkSizeWidth, StoreInkSizeHeight;

  // Store for brush colors
  private static Color StoreHighLightColor = Colors.Yellow, StoreInkColor = Colors.Black;

	// Queue with foregroundcolors
	private static System.Collections.Queue ColorQueue = new System.Collections.Queue();

	// Queue with backgroundbrushes
	private static System.Collections.Queue BrushQueue = new System.Collections.Queue();

	// since inheritance of Window does not work, the eventhandler have to be static methods and added after generation of the Window object

	// keyboard is pressed
	private static void InkCanvas_KeyDown(object sender, KeyEventArgs e)
	{
		Key Taste = e.Key;
			// the sender object is the object that generated the event
		InkCanvas objInkCanvas = (InkCanvas)sender;

    if (Keyboard.IsKeyDown(Key.RightCtrl) || Keyboard.IsKeyDown(Key.LeftCtrl))
// the following line only works with .Net 4.x
//		if (Keyboard.Modifiers.HasFlag(ModifierKeys.Control))
		{ // if Ctrl is pressed
			switch (Taste)
			{
				case Key.C: // copy marked area
						objInkCanvas.CopySelection();
						break;
				case Key.O: // open ink drawing
            Microsoft.Win32.OpenFileDialog objOpenDialog = new Microsoft.Win32.OpenFileDialog();
            objOpenDialog.Filter = "isf files (*.isf)|*.isf";
            if ((bool)objOpenDialog.ShowDialog())
            {
            	FileStream objFileStream = new FileStream(objOpenDialog.FileName, FileMode.Open);
             	objInkCanvas.Strokes.Add(new StrokeCollection(objFileStream));
             	objFileStream.Dispose();
            }
						break;
				case Key.P: // save grafic as PNG file
            Microsoft.Win32.SaveFileDialog objPNGDialog = new Microsoft.Win32.SaveFileDialog();
            objPNGDialog.Filter = "png files (*.png)|*.png";
            if ((bool)objPNGDialog.ShowDialog())
            {
            	FileStream objFileStream = new FileStream(objPNGDialog.FileName, FileMode.Create);
							System.Windows.Media.Imaging.RenderTargetBitmap	objRenderBitmap = new System.Windows.Media.Imaging.RenderTargetBitmap((int)objInkCanvas.ActualWidth, (int)objInkCanvas.ActualHeight, 96.0, 96.0, System.Windows.Media.PixelFormats.Default);
							objRenderBitmap.Render(objInkCanvas);
							System.Windows.Media.Imaging.BitmapFrame objBitmapFrame = System.Windows.Media.Imaging.BitmapFrame.Create(objRenderBitmap);
							System.Windows.Media.Imaging.PngBitmapEncoder objImgEncoder = new System.Windows.Media.Imaging.PngBitmapEncoder();
// alternative for JPG:								System.Windows.Media.Imaging.JpegBitmapEncoder objImgEncoder = new System.Windows.Media.Imaging.JpegBitmapEncoder();
							objImgEncoder.Frames.Add(objBitmapFrame);
							objImgEncoder.Save(objFileStream);
             	objFileStream.Dispose();
            }
						break;
					case Key.S: // save ink drawing
            Microsoft.Win32.SaveFileDialog objSaveDialog = new Microsoft.Win32.SaveFileDialog();
            objSaveDialog.Filter = "isf files (*.isf)|*.isf";
            if ((bool)objSaveDialog.ShowDialog())
            {
            	FileStream objFileStream = new FileStream(objSaveDialog.FileName, FileMode.Create);
             	objInkCanvas.Strokes.Save(objFileStream);
             	objFileStream.Dispose();
            }
						break;
				case Key.V: // paste marked area
						objInkCanvas.Paste();
						break;
				case Key.X: // cut marked area
						objInkCanvas.CutSelection();
						break;
			}
		}
		else
		{ // no Ctrl key is pressed
			if (Keyboard.Modifiers == ModifierKeys.None)
			{	// only when no other modifier keys are pressed
				switch (Taste)
				{
					case Key.B: // next background color
						Brush ActualBackColor = (Brush)BrushQueue.Dequeue();
						BrushQueue.Enqueue(ActualBackColor);
						objInkCanvas.Background = ActualBackColor;
						break;
					case Key.C: // clear window content
						objInkCanvas.Strokes.Clear();
						break;
					case Key.D: // switch to draw mode
						if (objInkCanvas.DefaultDrawingAttributes.IsHighlighter)
						{
              StoreHighLightSizeWidth = objInkCanvas.DefaultDrawingAttributes.Width;
              StoreHighLightSizeHeight = objInkCanvas.DefaultDrawingAttributes.Height;
              StoreHighLightColor = objInkCanvas.DefaultDrawingAttributes.Color;
              objInkCanvas.DefaultDrawingAttributes.StylusTip = StylusTip.Ellipse;
							objInkCanvas.DefaultDrawingAttributes.IsHighlighter = false;
              objInkCanvas.DefaultDrawingAttributes.Color = StoreInkColor;
              objInkCanvas.DefaultDrawingAttributes.Height = StoreInkSizeHeight;
              objInkCanvas.DefaultDrawingAttributes.Width = StoreInkSizeWidth;
						}
						objInkCanvas.EditingMode = InkCanvasEditingMode.Ink;
						break;
					case Key.E: // // switch to erase mode (and toggle it)
						switch (objInkCanvas.EditingMode)
						{
							case InkCanvasEditingMode.EraseByStroke:
								objInkCanvas.EditingMode = InkCanvasEditingMode.EraseByPoint;
								break;
							case InkCanvasEditingMode.EraseByPoint:
								objInkCanvas.EditingMode = InkCanvasEditingMode.EraseByStroke;
								break;
							case InkCanvasEditingMode.Ink:
								objInkCanvas.EditingMode = InkCanvasEditingMode.EraseByPoint;
								break;
						}
						break;
					case Key.H: // switch to highlight mode
						if (!objInkCanvas.DefaultDrawingAttributes.IsHighlighter)
						{
              StoreInkSizeWidth = objInkCanvas.DefaultDrawingAttributes.Width;
              StoreInkSizeHeight = objInkCanvas.DefaultDrawingAttributes.Height;
              StoreInkColor = objInkCanvas.DefaultDrawingAttributes.Color;
              objInkCanvas.DefaultDrawingAttributes.Color = StoreHighLightColor;
						}
						objInkCanvas.EditingMode = InkCanvasEditingMode.Ink;
						objInkCanvas.DefaultDrawingAttributes.IsHighlighter = true;
            objInkCanvas.DefaultDrawingAttributes.StylusTip = StylusTip.Rectangle;
            if (StoreHighLightSizeWidth > 0.0)
            {
             	objInkCanvas.DefaultDrawingAttributes.Height = StoreHighLightSizeHeight;
              objInkCanvas.DefaultDrawingAttributes.Width = StoreHighLightSizeWidth;
            }
						break;
					case Key.N: // next foreground color
						Color ActualFrontColor = (Color)ColorQueue.Dequeue();
						ColorQueue.Enqueue(ActualFrontColor);
						objInkCanvas.DefaultDrawingAttributes.Color = ActualFrontColor;
						break;
					case Key.Q: // close window
						// event is handled now
						e.Handled = true;
						// parent object is Window
						((Window)(objInkCanvas).Parent).Close();
						break;
					case Key.S: // start marking
						objInkCanvas.Select(new System.Windows.Ink.StrokeCollection());
						break;
					case Key.OemMinus: // shrink brush
						switch (objInkCanvas.EditingMode)
						{
							case InkCanvasEditingMode.EraseByPoint:
								if (objInkCanvas.EraserShape.Width > 3.0)
								{
									objInkCanvas.EraserShape = new RectangleStylusShape(objInkCanvas.EraserShape.Width - 2.0, objInkCanvas.EraserShape.Height - 2.0);
									// size change needs refresh to display
									objInkCanvas.EditingMode = InkCanvasEditingMode.None;
                  objInkCanvas.EditingMode = InkCanvasEditingMode.EraseByPoint;

								}
								break;
							case InkCanvasEditingMode.Ink:
                if (objInkCanvas.DefaultDrawingAttributes.Height > 3.0)
                {
                	objInkCanvas.DefaultDrawingAttributes.Height = objInkCanvas.DefaultDrawingAttributes.Height - 2.0;
                  objInkCanvas.DefaultDrawingAttributes.Width = objInkCanvas.DefaultDrawingAttributes.Width - 2.0;
                }
								break;
						}
						break;
					case Key.OemPlus: // enlarge brush
						switch (objInkCanvas.EditingMode)
						{
							case InkCanvasEditingMode.EraseByPoint:
								if (objInkCanvas.EraserShape.Width < 50.0)
								{
									objInkCanvas.EraserShape = new RectangleStylusShape(objInkCanvas.EraserShape.Width + 2.0, objInkCanvas.EraserShape.Height + 2.0);
									// size change needs refresh to display
									objInkCanvas.EditingMode = InkCanvasEditingMode.None;
                  objInkCanvas.EditingMode = InkCanvasEditingMode.EraseByPoint;

								}
								break;
							case InkCanvasEditingMode.Ink:
                if (objInkCanvas.DefaultDrawingAttributes.Height < 50.0)
                {
                	objInkCanvas.DefaultDrawingAttributes.Height = objInkCanvas.DefaultDrawingAttributes.Height + 2.0;
                  objInkCanvas.DefaultDrawingAttributes.Width = objInkCanvas.DefaultDrawingAttributes.Width + 2.0;
                }
								break;
						}
						break;
				}
			}


		}
	}

	// WPF requires STA model. Since C# uses MTA as default, the following compiler directive is required
	[STAThread]
	public static void Main()
	{
		// XAML string that defines the WPF controls
		string strXAML = @"
<Window xmlns=""http://schemas.microsoft.com/winfx/2006/xaml/presentation""
	xmlns:x=""http://schemas.microsoft.com/winfx/2006/xaml""
	x:Name=""Window"" Title=""WPF Ink demo    Keys: C D E H + - N B S Q Ctrl-X Ctrl-C Ctrl-V Ctrl-S Ctrl-O Ctrl-P"" WindowStyle=""ToolWindow"" ShowInTaskbar=""True"">
		<InkCanvas x:Name=""InkCanvas""></InkCanvas>
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

		// fill Queue with foreground colors
		ColorQueue.Enqueue(Colors.DarkBlue);
		ColorQueue.Enqueue(Colors.DarkGreen);
		ColorQueue.Enqueue(Colors.DarkCyan);
		ColorQueue.Enqueue(Colors.DarkRed);
		ColorQueue.Enqueue(Colors.DarkMagenta);
		ColorQueue.Enqueue(Colors.Gray);
		ColorQueue.Enqueue(Colors.DarkGray);
		ColorQueue.Enqueue(Colors.Blue);
		ColorQueue.Enqueue(Colors.Green);
		ColorQueue.Enqueue(Colors.Cyan);
		ColorQueue.Enqueue(Colors.Red);
		ColorQueue.Enqueue(Colors.Magenta);
		ColorQueue.Enqueue(Colors.Yellow);
		ColorQueue.Enqueue(Colors.White);
		ColorQueue.Enqueue(Colors.Black);

		// fill Queue with background brushes
		BrushQueue.Enqueue(Brushes.Yellow);
		BrushQueue.Enqueue(Brushes.Magenta);
		BrushQueue.Enqueue(Brushes.Red);
		BrushQueue.Enqueue(Brushes.Cyan);
		BrushQueue.Enqueue(Brushes.Green);
		BrushQueue.Enqueue(Brushes.Blue);
		BrushQueue.Enqueue(Brushes.DarkGray);
		BrushQueue.Enqueue(Brushes.Gray);
		BrushQueue.Enqueue(Brushes.DarkMagenta);
		BrushQueue.Enqueue(Brushes.DarkRed);
		BrushQueue.Enqueue(Brushes.DarkCyan);
		BrushQueue.Enqueue(Brushes.DarkGreen);
		BrushQueue.Enqueue(Brushes.DarkBlue);
		BrushQueue.Enqueue(Brushes.Black);
		BrushQueue.Enqueue(Brushes.White);

		// search object of InkCanvas control
		InkCanvas objInkCanvas = (InkCanvas)objWindow.FindName("InkCanvas");

		// add eventhandler (the last parameter false means, that the handler is not called, when an event is already handled)
		objInkCanvas.AddHandler(FrameworkElement.KeyDownEvent, new KeyEventHandler(InkCanvas_KeyDown), true);

		// define Tooltip for the window
		objWindow.ToolTip = @"
C - Clear
D - Draw
E - Erase
H - Highlight
+ - - Size of brush
N B - Next color  Next background
S - Select
Q - Quit
Ctrl-X Ctrl-C Ctrl-V - Cut Copy Paste
Ctrl-S Ctrl-O Ctrl-P - Save / Open as ISF file, Save as PNG file
";

		// and show WPF window
		objWindow.ShowDialog();
	}
}
